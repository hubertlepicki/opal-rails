require 'opal/rails/spec_builder'
require 'fileutils'
require 'pathname'

class OpalSpecController < ActionController::Base
  helper_method :spec_files, :pattern, :clean_spec_path, :runner_name
  helper_method :check_errors_for, :builder

  def run
    logical_path = builder.runner_logical_path
    sprockets = Rails.application.assets
    runner = builder.runner_pathname
    runner.open('w') do |file|
      file << builder.main_code
      file.fsync
    end
    written_to_disk = runner.read
    unless written_to_disk == builder.main_code
      raise "Something's wrong: written_to_disk: #{written_to_disk.inspect}"
    end
    runner_asset = sprockets.load "file://#{runner.to_s}?type=application/javascript"
    # runner_asset = sprockets.find_asset(logical_path) or raise("can't find asset #{logical_path}")
    runner_asset or raise("can't find asset #{logical_path}")
    render locals: { runner: runner_asset, runner_code: sprockets.load(runner_asset.included.last).to_s }
  end


  private

  # This will deactivate the requirement to precompile assets in this controller
  # as specs shouldn't go to production anyway.
  def check_errors_for(*)
    #noop
  end

  def pattern
    params[:pattern]
  end

  def builder
    @builder ||= Opal::Rails::SpecBuilder.new(
      spec_location: Rails.application.config.opal.spec_location,
      sprockets: Rails.application.config.assets,
      pattern: pattern,
    )
  end

  def runner_name
    builder.runner_pathname.basename.to_s.gsub(/(\.js)?\.rb$/, '')
  end

  delegate :spec_files, :clean_spec_path, to: :builder
end
