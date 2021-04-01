# frozen_string_literal: true

require 'mongo'
MONGO = Mongo::Client.new(['127.0.0.1:27017'], database: 'pubg')
COLLECTION = MONGO[:players]

MAPS = {
  "Baltic_Main": 'Erangel',
  "Chimera_Main": 'Paramo',
  "Desert_Main": 'Miramar',
  "DihorOtok_Main": 'Vikendi',
  "Erangel_Main": 'Erangel',
  "Heaven_Main": 'Haven',
  "Range_Main": 'Camp Jackal',
  "Savage_Main": 'Sanhok',
  "Summerland_Main": 'Karakin'
}.freeze
class Match
  class << self
    def get(userid)
      m = COLLECTION.find({ userid: userid })
      if m.count.positive?
        m.first['matches'].sort_by { |hsh| hsh['date'] }.reverse
      else
        {}
      end
    end

    def get_matches_ids(userid)
      get(userid).map { |x| x['id'] }
    end

    def add(userid, match)
      q = if exist?(userid)
            COLLECTION.update_one({ "userid": userid }, { "$addToSet": { 'matches' => match } })
          else
            COLLECTION.insert_one({ "userid": userid, "matches": [match] })
          end
      if q.n.positive?
        true
      else
        false
      end
    end

    def exits_match?(userid, match)
      m = COLLECTION.find({ "$and": [{ "userid": userid }, { "matches": { "$elemMatch": { "id": match } } }] }).limit(1)
      if m.count.positive?
        true
      else
        false
      end
    end

    def set_match(id, userid, match, payload)
      teams = payload.select { |x| x['type'] == 'roster' }
      players_list = payload.select { |x| x['type'] == 'participant' }
      telemetry = payload.select { |x| x['type'] == 'asset' }
      player = get_player(players_list, userid)

      team = match['gameMode'] == 'solo' ? false : set_team(teams, player['id'], players_list)

      {
        id: id,
        map: get_realname_map(match['mapName']),
        date: match['createdAt'],
        mode: match['gameMode'],
        kills: player['attributes']['stats']['kills'],
        place: player['attributes']['stats']['winPlace'],
        team: team,
        telemetry: telemetry[0]['attributes']['URL']
      }
    end

    def save_matches(userid, matches)
      current_matches = get_matches_ids(userid)
      matches.each do |m|
        next if current_matches.include?(m) && !current_matches.empty?

        match = {}
        response = Pubg.get_match(m)
        match = set_match(m, userid, response['data']['attributes'], response['included']) if response
        Match.add(userid, match)
      end
    end

    private

    def exist?(userid)
      m = COLLECTION.find({ userid: userid })
      if m.count.positive?
        true
      else
        false
      end
    end

    def set_team(teams, id, players)
      team = get_team_ids(teams, id)
      response = []
      team.each do |t|
        x = get_player(players, t, true)
        response.push({
                        "gametag": x['attributes']['stats']['name'],
                        "kills": x['attributes']['stats']['kills'],
                        "kill_place": x['attributes']['stats']['killPlace'],
                        "console": x['attributes']['shardId']
                      })
      end
      response
    end

    def get_team_ids(teams, player)
      team = teams.select { |t| t['relationships']['participants']['data'].any? { |x| x['id'] == player } }
      team.last['relationships']['participants']['data'].map { |t| t['id'] }
    end

    def get_player(players_list, id, by_playerid = false)
      if by_playerid
        players_list.select { |x| x['id'] == id }.last
      else
        players_list.select { |x| x['attributes']['stats']['playerId'] == id }.last
      end
    end

    def get_realname_map(name)
      MAPS[name.to_sym]
    end
  end
end
