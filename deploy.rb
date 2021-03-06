require 'rubygems'
require 'zlib'

JQUERY_MANIFEST_FILE = 'mask.jquery.json'
JMASK_FILE = 'jquery.mask.js'
JMASK_MIN_FILE = 'jquery.mask.min.js'
JMASK_GZIP_FILE = 'jquery.mask.min.js.gz'
JMASK_VERSION = `stepup version --next-release`.delete("\n")
BOWER_MANIFEST_FILE = 'bower.json'

abort("No notes, do deal.") if JMASK_VERSION.empty?

puts '# PUTTING NEW VERSION INSIDE OF JQUERY MASK FILE'
unversioned_jmask_file = File.open(JMASK_FILE, 'rb') { |file| file.read }
File.open(JMASK_FILE, 'w') do |file| 
  file.write(unversioned_jmask_file.gsub(/\* @version: (v[0-9.+]+)/, "\* @version: #{JMASK_VERSION}"))
end

puts '# UPGRADING BOWER MANIFEST FILE'
bower_manifest_file = File.open(BOWER_MANIFEST_FILE, 'rb') { |file| file.read }
File.open(BOWER_MANIFEST_FILE, 'w') do |file|
  file.write(bower_manifest_file.gsub(/"version": "([0-9.+]+)"/, "\"version\": \"#{JMASK_VERSION.gsub("v", "")}\""))
end

puts '# UPGRADING JQUERY PLUGINS MANIFEST FILE'
jquery_manifest_file = File.open(JQUERY_MANIFEST_FILE, 'rb') { |file| file.read }
File.open(JQUERY_MANIFEST_FILE, 'w') do |file| 
  file.write(jquery_manifest_file.gsub(/"version": "([0-9.+]+)"/, "\"version\": \"#{JMASK_VERSION.gsub("v", "")}\""))
end

puts '# GENERATING MIN FILE'
File.open(JMASK_FILE, 'r') do |file| 
  minFile = File.open(JMASK_MIN_FILE, 'w')
  minFile.puts("// jQuery Mask Plugin #{JMASK_VERSION}")
  minFile.puts("// github.com/igorescobar/jQuery-Mask-Plugin") 
  minFile.puts(`java -jar ../clojure-compiler/compiler.jar --js jquery.mask.js --charset UTF-8`)
  minFile.close
end

puts '# GENERATING GZIP FILE'
File.open(JMASK_GZIP_FILE, 'w') do |f|
  minFile = File.open(JMASK_MIN_FILE, 'r').read
  gz = Zlib::GzipWriter.new(f)
  gz.write minFile
  gz.close
end

puts '# GENERATING A NEW COMMIT WITH VERSIONED FILEs'
`git commit -am 'generating jquery mask files #{JMASK_VERSION}'`

puts '# PUSHING CHANGES TO REMOTE'
`git pull --rebase && git push`

puts '# CREATING NEW VERSION'
`stepup version create --no-editor`

puts '# DONE'