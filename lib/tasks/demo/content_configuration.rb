require 'hashie/mash'
require 'yaml'
require 'erb'
require_relative 'content_configuration_yaml_methods'

# Reads in a YAML file containg configuration for a course and its students
class Demo::ContentConfiguration
  # Yaml files will be located inside this directory
  DEFAULT_CONFIG_DIR = File.join(File.dirname(__FILE__), 'configurations')
  EXPLICIT_CONFIGURATIONS = ['large', 'ludicrous']
  class ConfigFileParser
    def initialize(file_path)
      @content = File.read(file_path)
      @helpers = Demo::ContentConfigurationYamlMethods.new
      @file_path = file_path
    end

    def perform
      template = ERB.new(@content)
      template.filename = @file_path
      YAML.load template.result(@helpers.get_binding)
    end

    def self.perform(file_path)
      new(file_path).perform
    end
  end

  extend Forwardable

  def self.[](name)
    # The directory for the config files can be either set using either
    # config_directory block (which sets it's value using Thread.current),
    # the CONFIG environmental variable or the default
    config_directory = Thread.current[:config_directory] || ENV['CONFIG'] || DEFAULT_CONFIG_DIR
    files = if :all == name
              Dir[File.join(config_directory, '*.yml')].reject{ |path|
                EXPLICIT_CONFIGURATIONS.include?( File.basename(path,'.yml') )
              }
            else
              Dir[File.join(config_directory, "#{name}*.yml")]
            end
    files.map{|file| self.new(file) }
  end

  def_delegators :@configuration, :course_name, :teachers, :periods, :is_concept_coach,
                 :appearance_code, :catalog_offering_salesforce_book_name,
                 :catalog_offering_is_concept_coach, :reading_processing_instructions

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: ConfigFileParser)
    validate_config
  end

  def url_base
    @configuration.url_base || Rails.application.secrets.openstax['cnx']['archive_url']
  end

  def webview_url_base
    @configuration.webview_url_base
  end

  def assignments
    @configuration.assignments || []
  end
  def auto_assign
    @configuration.auto_assign || []
  end

  def cnx_book(book_version=:defined)
    version = if book_version.to_sym != :defined
                book_version.to_sym == :latest ? '' : "@#{book_version}"
              elsif @configuration.cnx_book_version.blank? || @configuration.cnx_book_version == 'latest'
                ''
              else
                "@#{@configuration.cnx_book_version}"
              end
    "#{@configuration.cnx_book_id}#{version}"
  end

  def course
    @course ||= CourseProfile::Models::Profile.where(name: course_name)
                                              .order{created_at.desc}.first!.course
  end

  def self.with_config_directory( directory )
    prev_config, Thread.current[:config_directory] = Thread.current[:config_directory], directory
    yield self
  ensure
    Thread.current[:config_directory] = prev_config
  end

  def get_period(id)
    @configuration.periods.detect{|period| period['id'] == id}
  end

  private

  def validate_config
    # make sure the titles for assignments are unique
    titles = assignments.map(&:title)
    duplicate = titles.detect {|e| titles.rindex(e) != titles.index(e) }
    raise "Assignment #{duplicate} for #{course_name} is listed more than once" if duplicate
    # loop through each assignment and verify that the students match the roster for the period
    assignments.each do | assignment |
      assignment.periods.each_with_index do | period, index |
        period_config = get_period(period.id)
        if period_config.nil?
          raise "Unable to find period # #{index} id #{period.id} for assignment #{assignment.title}"
        end
        if period_config.students.sort != period.students.keys.sort
          raise "Students assignments for #{course_name} period #{period_config.name} do not match for assignment #{assignment.title}"
        end
      end
    end
  end
end
