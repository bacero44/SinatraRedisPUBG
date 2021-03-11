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
  attr_accessor :gametag
  attr_accessor :userid
  attr_reader :stats
  attr_reader :mastery
  attr_reader :weapons

  def initialize(gametag, userid = nil)
    @gametag = gametag
    @userid = userid
    @stats = []
    @mastery = []
  end

  def fund?
    if userid.nil?
      false
    else
      true
    end
  end

  def get
    ask_id if userid.nil?

    if fund? && ask_stats && ask_mastery
      true
    else
      false
    end
  end

  private

  def ask_id
    response = request("https://api.pubg.com/shards/xbox/players?filter[playerNames]=#{gametag}")
    @userid = response[0]['id'] if response
  end

  def ask_stats
    if fund?
      response = request("https://api.pubg.com/shards/xbox/players/#{userid}/seasons/lifetime")
      if response
        response = response['attributes']['gameModeStats']
        seter_stats(response)
      else
        false
      end

      true
    else
      false
    end
  end

  def ask_mastery
    if fund?
      response = request("https://api.pubg.com/shards/xbox/players/#{userid}/weapon_mastery")
      if response
        seter_mastery(response['attributes']['weaponSummaries'])
        true
      else
        false
      end
    else
      false
    end
  end

  def request(url)
    # puts '++++CALL PUBG API++++++++++++++'
    response = HTTParty.get(url, headers: {
                              'Content-Type' => 'application/json',
                              'accept' => 'application/vnd.api+json',
                              'Authorization' => "Bearer #{CONFIG['pubg_api_key']}"
                            })
    if response.code == 200
      response['data']
    else
      false
    end
  end

  def seter_mastery(mastery_list)
    #  TODO: simplify this method
    @@weapons.each do |w|
      m = mastery_list[w[:api_name]]

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
  end

  def seter_stats(stats_list)
    @@game_types.each do |g|
      stats.push({
                   type_name: g,
                   assists: stats_list[g]['assists'],
                   damage: stats_list[g]['damageDealt'],
                   kills: stats_list[g]['kills'],
                   longest_kill: stats_list[g]['longestKill'],
                   max_kill_streaks: stats_list[g]['maxKillStreaks'],
                   team_kills: stats_list[g]['teamKills'],
                   tops_ten: stats_list[g]['top10s'],
                   wins: stats_list[g]['wins'],
                   head_shot_kills: stats_list[g]['headshotKills']
                 })
    end
  end
end
