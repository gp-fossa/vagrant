require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Create < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version create [options] organization/box-name version"
              o.separator ""
              o.separator "Creates a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-d", "--description DESCRIPTION", String, "A description for this version") do |d|
                options[:description] = d
              end
              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Specify your Vagrant Cloud username or email address") do |t|
                options[:username] = u
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 2
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])
            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            version = argv[1]

            create_version(org, box_name, version, @client.token, options)
          end

          def create_version(org, box_name, box_version, access_token, options)
            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            version = VagrantCloud::Version.new(box, box_version, nil, options[:description], access_token)

            begin
              success = version.create_version
              @env.ui.success(I18n.t("cloud_command.version.create_success", version: box_version, org: org, box_name: box_name))
              VagrantPlugins::CloudCommand::Util.format_box_results(success.compact, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.version.create_fail", version: box_version, org: org, box_name: box_name))
              @env.ui.error(e)
              return 1
            end
            return 1
          end
        end
      end
    end
  end
end
