require_relative './di_container'
require 'rspec/given'
require 'rspec/autorun'

RSpec::Given.use_natural_assertions

class ConsoleAppender
end

class Logger
  attr_accessor :appender
end

class FauxDB
end

class RealDB
  attr_accessor :username, :password
  def initialize(username, password)
    @username, @password = username, password
  end
end

class App
  attr_accessor :logger, :db
  def initialize(logger=nil)
    @logger = logger
  end
end

describe DiContainer do
  let(:container) { DiContainer.new }

  context "when creating objects" do
    Given { container.register(:app) { App.new } }
    Then  { container[:app].kind_of?(App) }
  end

  describe "returning the same object every time" do
    Given(:app) { App.new }
    Given { container.register(:app) { app } }
    Then { container[:app] == app }
  end

  describe "clearing the cache explicitly" do
    Given!(:_) { container.register(:app) { App.new } }
    Given!(:app_before) { container[:app] }
    When(:app_after) {
      container.clear_cache!
      container[:app]
    }
    Then { app_before != app_after }
  end

  context "when contructing dependent objects" do
    Given { container.register(:app) { |c| App.new(c[:logger]) } }
    Given { container.register(:logger) { Logger.new } }
    Given(:app) { container[:app] }
    Then { app.logger == container[:logger] }
  end

  context "when constructing dependent objects with setters" do
    Given {
      container.register(:app) { |c|
        App.new.tap { |obj|
          obj.db = c[:database]
        }
      }
    }
    Given { container.register(:database) { FauxDB.new } }
    Given(:app) { container[:app] }

    Then { app.db == container[:database] }
  end

  context "when constructing multiple dependent objects" do
    Given {
      container.register(:app) { |c|
        App.new(c[:logger]).tap { |obj|
          obj.db = c[:database]
        }
      }
    }
    Given { container.register(:logger) { Logger.new } }
    Given { container.register(:database) { FauxDB.new } }
    Given(:app) { container[:app] }
    Then { app.logger == container[:logger] }
    Then { app.db == container[:database] }
  end

  context "when constructing chains of dependencies" do
    Given { container.register(:app) { |c| App.new(c[:logger]) } }
    Given {
      container.register(:logger) { |c|
        Logger.new.tap { |obj|
          obj.appender = c[:logger_appender]
        }
      }
    }
    Given { container.register(:logger_appender) { ConsoleAppender.new } }
    Given { container.register(:database) { FauxDB.new } }
    Given(:logger) { container[:app].logger }

    Then { logger.appender == container[:logger_appender] }
  end

  context "when constructing literals" do
    Given { container.register(:database) { |c| RealDB.new(c[:username], c[:userpassword]) } }
    Given { container.register(:username) { "user_name_value" } }
    Given { container.register(:userpassword) { "password_value" } }
    Given(:db) { container[:database] }

    Then { db.username == "user_name_value" }
    Then { db.password == "password_value" }
  end

  describe "Errors" do
    context "with missing services" do
      When(:result) { container[:undefined_service_name] }
      Then { result == have_failed(DiContainer::MissingItemError, /undefined_service_name/) }
    end

    context "with duplicate service names" do
      Given { container.register(:duplicate_name) { 0 } }
      When(:result) { container.register(:duplicate_name) { 0 } }
      Then { result == have_failed(DiContainer::DuplicateItemError, /duplicate_name/) }
    end
  end

  describe "Registering env variables" do
    context "which exist in ENV" do
      Given { ENV["SHAZ"] = "bot" }
      Given { container.register_env(:shaz) }
      Then  { container[:shaz] == "bot" }
    end

    context "which don't exist in optional hash" do
      When(:result) { container.register_env(:dont_exist_in_env_or_optional_hash) }
      Then { result == have_failed(DiContainer::EnvironmentVariableNotFound) }
    end
  end
end
