require 'zeitwerk'
# require 'sinatra/cookies'
# require 'yaml'
require 'logger'
# require 'sequel'
# require_relative 'app'
# App.logger = Logger.new('log/processing.log', 'monthly')
# App.logger.level = Logger::INFO
# App.logger.info('App start')

# begin
#   App.config = YAML.load_file('config.yml') || {}
# rescue Exception => e
#   App.logger.error("config not loaded with #{e.message}")
#   raise
# end

# begin
#   db_url = ENV['DATABASE_URL'] || App.config['db'] || 'postgres://localhost/wdca'
#   App.db = Sequel.connect(db_url)
#   App.db.extension :pg_json
# rescue Exception => e
#   App.logger.error("db not connected with #{e.message}")
#   raise
# end

loader = Zeitwerk::Loader.new
# Dir['./app/*'].each { |p| loader.push_dir(p) }
loader.setup
