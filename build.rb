#!/usr/bin/env ruby

require 'aws-sdk'
AWS.config access_key_id: ENV['S3_ACCESS_ID'], secret_access_key: ENV['S3_SECRET_KEY']
s3 = AWS::S3.new
bucket = s3.buckets['zooniverse-demo']
path = 'light_curves'

`rm -rf build`
`haw build`

working_directory = File.expand_path Dir.pwd
Dir.chdir 'build'

Dir['*.js'].each do |js|
  `gzip -9 -c #{ js } > temp.js`
  `mv temp.js #{ js }`
end

Dir['*.css'].each do |css|
  `gzip -9 -c #{ css } > temp.css`
  `mv temp.css #{ css }`
end

to_upload = []

if ARGV[1] == 'quick'
  %w(js css html).each{ |ext| to_upload << Dir["**/*.#{ ext }*"] }
  to_upload.flatten!
else
  to_upload = Dir['**/*'].reject{ |path| File.directory? path }
end

to_upload.delete 'index.html'
total = to_upload.length

to_upload.each.with_index do |file, index|
  content_type = case File.extname(file)
  when '.html'
    'text/html'
  when '.js'
    'application/javascript'
  when '.css'
    'text/css'
  when '.gz'
    'application/x-gzip'
  when '.ico'
    'image/x-ico'
  else
    `file --mime-type -b #{ file }`.chomp
  end
  
  puts "#{ '%2d' % (index + 1) } / #{ '%2d' % (total + 1) }: Uploading #{ file } as #{ content_type }"
  options = { file: file, acl: :public_read, content_type: content_type }
  
  if content_type == 'application/javascript' || content_type == 'text/css'
    options[:content_encoding] = 'gzip'
  end
  
  bucket.objects["#{ path }/#{ file }"].write options
end

puts "#{ '%2d' % (total + 1) } / #{ '%2d' % (total + 1) }: Uploading index.html as text/html"
bucket.objects["#{ path }/index.html"].write file: 'index.html', acl: :public_read, content_type: 'text/html', cache_control: 'no-cache, must-revalidate'

Dir.chdir working_directory
`rm -rf build`
puts 'Done!'
