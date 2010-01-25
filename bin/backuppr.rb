#!/usr/bin/env ruby

#
# Tiny script around rdiff-backup to automate backups since Time Machine sucks.
#
# I do not expect this to be of any use to anyone else but you never know.
#
# You notice that generally you will specifically indicate which directories
# you want to back up. If you really need to back up your entire 250GiB drive,
# just include the / directory.
#
# The backups are stored using their relative paths appended to the base
# backup dir given as the :mount configuration option.
#
# Each directory may have stuff in it that you do not want. You can either
# set the default disposition to include or to exclude, and then give
# exceptions to the rule. The exceptions should be given relative to the
# base directory you are working with.
#
# The configuration file should be YAML and it can be given as an argument
# to the program or live in the standard location ~/.backuppr/cludes.yaml.
#
# The 'cludes file looks like this:
#
#  ---
#  :mount:    /path/to/backup/dir
#
#  :dirs:
#
#    /Users/suck:
#      :default:     :include
#      :exclude:
#        - .fseventsd
#        - .macports
#        - .Spotlight-V100
#        - .TemporaryItems
#        - .Trash
#        - .Trashes
#        - code/external
#        - Documents/Parallels
#        - Documents/Virtual\ Machines
#        - Downloads
#
#    /private/etc:
#      :default:     :include
#
#    /private/var:
#      :default:     :exclude
#      :include:
#        - log
#

require "fileutils"
require "ostruct"
require "yaml"


$config = OpenStruct.new(YAML.load_file(ARGV.shift || "#{ENV["HOME"]}/.backuppr/cludes.yaml"))

$config.script      ||= "/opt/local/bin/rdiff-backup"
$config.options     ||= %w[
                            --create-full-path
                            --exclude-special-files
                            --override-chars-to-quote ''
                            --terminal-verbosity 6

                         ].join " "

$config.default_excludes = %w[/proc /tmp /mnt]

abort "Directory #{$config.mount} not available!" unless File.directory? $config.mount


$config.dirs.each do |dir, cludes|

  unless File.directory? dir
    $stderr.puts "Error: #{dir} does not exist and was not backed up!"
    next
  end

  dir       = File.expand_path dir
  backup    = $config.mount + dir

  excludes  = cludes[:exclude].map {|file| "--exclude **/#{file}" }.join(" ") rescue ""
  includes  = cludes[:include].map {|file| "--include **/#{file}" }.join(" ") rescue ""

  excludes[0, 0] = " --exclude \"**\" " if cludes[:default] == :exclude

  command = "#{$config.script} #{$config.options} --force #{includes} #{excludes} #{dir} #{backup}"
  puts command
  system command

end

