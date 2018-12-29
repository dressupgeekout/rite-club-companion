MY_GEMS = [
  "mrbgems/mruby-compiler",
  "mrbgems/mruby-print",
  {:git => "https://github.com/iij/mruby-dir.git"},
]

MRuby::Build.new do |conf|
  toolchain :gcc
  
  conf.cc { |cc| cc.command = 'gcc' }
  conf.linker { |linker| linker.command = 'gcc' }
  conf.archiver { |archiver| archiver.command = 'ar' }

  MY_GEMS.each { |g| conf.gem(g) }
end


MRuby::CrossBuild.new('mingw-w64') do |conf|
  toolchain :gcc

  conf.cc { |cc| cc.command = 'x86_64-w64-mingw32-gcc' }
  conf.linker { |linker| linker.command = 'x86_64-w64-mingw32-gcc' }
  conf.archiver { |archiver| archiver.command = 'x86_64-w64-mingw32-ar' }

  MY_GEMS.each { |g| conf.gem(g) }
end
