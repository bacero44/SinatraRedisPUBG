# frozen_string_literal: true

require 'httparty'

CONFIG = YAML.load_file('app.yml')
class Pubg
  @@game_types = %w[duo solo squad]
  @@weapons = [
    { name: 'akm', api_name: 'Item_Weapon_AK47_C' },
    { name: 'aug', api_name: 'Item_Weapon_AUG_C' },
    { name: 'awm', api_name: 'Item_Weapon_AWM_C' },
    { name: 'barreta', api_name: 'Item_Weapon_Berreta686_C' },
    { name: 'beryl', api_name: 'Item_Weapon_BerylM762_C' },
    { name: 'bizon', api_name: 'Item_Weapon_BizonPP19_C' },
    { name: 'dbs', api_name: 'Item_Weapon_DP12_C' },
    { name: 'dp-28', api_name: 'Item_Weapon_DP28_C' },
    { name: 'desert eagle', api_name: 'Item_Weapon_DesertEagle_C' },
    { name: 'slr', api_name: 'Item_Weapon_FNFal_C' },
    { name: 'p18c', api_name: 'Item_Weapon_G18_C' },
    { name: 'g36c', api_name: 'Item_Weapon_G36C_C' },
    { name: 'groza', api_name: 'Item_Weapon_Groza_C' },
    { name: 'm416', api_name: 'Item_Weapon_HK416_C' },
    { name: 'kar98', api_name: 'Item_Weapon_Kar98k_C' },
    { name: 'm16a4', api_name: 'Item_Weapon_M16A4_C' },
    { name: 'p1911', api_name: 'Item_Weapon_M1911_C' },
    { name: 'm249', api_name: 'Item_Weapon_M249_C' },
    { name: 'm24c', api_name: 'Item_Weapon_M24_C' },
    { name: 'm9 beretta', api_name: 'Item_Weapon_M9_C' },
    { name: 'mg3', api_name: 'Item_Weapon_MG3_C' },
    { name: 'mp5k', api_name: 'Item_Weapon_MP5K_C' },
    { name: 'mini14', api_name: 'Item_Weapon_Mini14_C' },
    { name: 'mk14', api_name: 'Item_Weapon_Mk14_C' },
    { name: 'mk47 mutant', api_name: 'Item_Weapon_Mk47Mutant_C' },
    { name: 'mosin nagant', api_name: 'Item_Weapon_Mosin_C' },
    { name: 'nagant m1895', api_name: 'Item_Weapon_NagantM1895_C' },
    { name: 'qbu', api_name: 'Item_Weapon_QBU88_C' },
    { name: 'qbz', api_name: 'Item_Weapon_QBZ95_C' },
    { name: 'r45', api_name: 'Item_Weapon_Rhino_C' },
    { name: 'scar-l', api_name: 'Item_Weapon_SCAR-L_C' },
    { name: 'sks', api_name: 'Item_Weapon_SKS_C' },
    { name: 's12k', api_name: 'Item_Weapon_Saiga12_C' },
    { name: 'sawed off', api_name: 'Item_Weapon_Sawnoff_C' },
    { name: 'thompson', api_name: 'Item_Weapon_Thompson_C' },
    { name: 'ump45', api_name: 'Item_Weapon_UMP_C' },
    { name: 'micro uzi', api_name: 'Item_Weapon_UZI_C' },
    { name: 'vss', api_name: 'Item_Weapon_VSS_C' },
    { name: 'vector', api_name: 'Item_Weapon_Vector_C' },
    { name: 'win94', api_name: 'Item_Weapon_Win1894_C' },
    { name: 'winchester', api_name: 'Item_Weapon_Winchester_C' },
    { name: 'skorpion', api_name: 'Item_Weapon_vz61Skorpion_C' }
  ]

  class << self
    def get_player(nametag)
      response = request("https://api.pubg.com/shards/xbox/players?filter[playerNames]=#{nametag}")
      if response
        response[0]['id']
      else
        false
      end
    end

    def get_stats(userid)
      response = request("https://api.pubg.com/shards/xbox/players/#{userid}/seasons/lifetime")
      if response
        # TODO: GET ONLY first 20 as max per type
        duo = response['relationships']['matchesDuo']['data'].map { |d| d['id'] }
        squad = response['relationships']['matchesSquad']['data'].map { |d| d['id'] }
        solo = response['relationships']['matchesSolo']['data'].map { |d| d['id'] }
        matches = [duo, squad, solo].reduce([], :concat)
        save_matches(userid, matches)
        set_stats(response['attributes']['gameModeStats'])
      else
        false
      end
    end

    def get_mastery(userid)
      response = request("https://api.pubg.com/shards/xbox/players/#{userid}/weapon_mastery")
      if response
        response = response['attributes']['weaponSummaries']
        set_mastery(response)
      else
        false
      end
    end

    private

    def request(url, only_data = false)
      puts '++++CALL PUBG API++++++++++++++'
      response = HTTParty.get(url, headers: {
                                'Content-Type' => 'application/json',
                                'accept' => 'application/vnd.api+json',
                                'Authorization' => "Bearer #{CONFIG['pubg_api_key']}"
                              })
      if response.code == 200
        if only_data
          response
        else
          response['data']
        end

      else
        false
      end
    end

    def set_stats(payload)
      stats = []
      @@game_types.each do |g|
        stats.push({
                     type_name: g,
                     assists: payload[g]['assists'],
                     damage: payload[g]['damageDealt'],
                     kills: payload[g]['kills'],
                     longest_kill: payload[g]['longestKill'],
                     max_kill_streaks: payload[g]['maxKillStreaks'],
                     team_kills: payload[g]['teamKills'],
                     tops_ten: payload[g]['top10s'],
                     wins: payload[g]['wins'],
                     head_shot_kills: payload[g]['headshotKills']
                   })
      end
      stats
    end

    def set_mastery(payload)
      mastery = []
      @@weapons.each do |w|
        m = payload[w[:api_name]]
        mastery.push({
                       name: w[:name],
                       level: m.nil? ? 0 : m['LevelCurrent'],
                       head_shots: m.nil? ? 0 : m['StatsTotal']['HeadShots'],
                       most_head_shots: m.nil? ? 0 : m['StatsTotal']['MostHeadShotsInAGame'],
                       kills: m.nil? ? 0 : m['StatsTotal']['Kills'],
                       most_kills: m.nil? ? 0 : m['StatsTotal']['MostKillsInAGame'],
                       groggies: m.nil? ? 0 : m['StatsTotal']['Groggies'],
                       most_groggies: m.nil? ? 0 : m['StatsTotal']['MostGroggiesInAGame']
                     })
      end
      mastery
    end

    def save_matches(userid, payload)
      current_matches = Match.get_matches(userid)
      payload.each do |m|
        next if current_matches.include? m && !current_matches.empty?

        match = {}
        response = request("https://api.pubg.com/shards/steam/matches/#{m}", true)
        match = set_match(m, userid, response['data']['attributes'], response['included']) if response
        Match.add(userid, match)
      end
    end

    def set_match(id, userid, match, player)
      player = player.select { |x| x['type'] == 'participant' }
      player = player.select { |x| x['attributes']['stats']['playerId'] == userid }
      {
        id: id,
        map: match['mapName'],
        date: match['createdAt'],
        mode: match['gameMode'],
        kills: player.last['attributes']['stats']['kills'],
        place: player.last['attributes']['stats']['winPlace']
      }
    end
  end
end
