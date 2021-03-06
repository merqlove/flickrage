# frozen_string_literal: true
require 'logger'

module Flickrage
  # Shared logger
  #
  class Log
    attr_reader   :shell
    attr_accessor :quiet, :verbose
    attr_writer   :buffer, :instance

    def initialize(options = {})
      @verbose = Flickrage.config.verbose
      @quiet   = Flickrage.config.quiet
      options.each { |key, option| instance_variable_set(:"@#{key}", option) }
      instance.level = Flickrage.config.logger_level if instance
    end

    def instance
      @instance ||= Flickrage.config.logger
    end

    def buffer
      @buffer ||= %w()
    end

    def shell=(shell)
      @shell = shell unless quiet
    end

    def close
      instance.close if instance
    end

    %w(debug info warn error fatal unknown).each_with_index do |name, severity|
      define_method(:"#{name}") { |*args, &block| log severity, *args, &block }
    end

    %w(yes? no?).each do |name|
      define_method(:"#{name}") do |statement, color = :green|
        shell.send(:"#{name}", statement, color) if shell
      end
    end

    def print_table(*args)
      args[0]&.each { |row| instance.info(row) } if instance
      shell.print_table(*args) if shell
    end

    def ask(statement, color: :green, path: false)
      shell.ask(statement, color, path: path) if shell
    end

    def add_padding
      shell.say_status('', '') if shell
    end

    def log(severity, message = nil, progname = nil, &block)
      buffer << message
      instance.add(severity, message, progname, &block) if instance.respond_to?(:add)

      say(message, color(severity)) unless print?(severity)
    end

    protected

    def print?(type)
      (type == Logger::DEBUG && !verbose) || quiet
    end

    def say(message, color)
      shell.say message, color if shell
    end

    def color(severity)
      case severity
      when 0
        :white
      when 3
        :red
      when 2
        :yellow
      else
        :green
      end
    end
  end
end
