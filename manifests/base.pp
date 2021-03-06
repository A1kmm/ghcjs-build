exec { "apt-update":
    command => "apt-get update",
    path => "/usr/bin"
}
package { 'ghc': ensure => present, require => [Exec[apt-update]] }
package { 'cabal-install': ensure => present, require => [Exec[apt-update]] }
package { 'libwebkitgtk-3.0-dev': ensure => present, require => [Exec[apt-update]] }
package { 'happy': ensure => present, require => [Exec[apt-update]] }
package { 'alex': ensure => present, require => [Exec[apt-update]] }
package { 'autoconf': ensure => present, require => [Exec[apt-update]] }
package { 'libtool': ensure => present, require => [Exec[apt-update]] }
package { 'darcs': ensure => present, require => [Exec[apt-update]] }
package { 'git': ensure => present, require => [Exec[apt-update]] }
package { 'libncurses5-dev': ensure => present, require => [Exec[apt-update]] }
package { 'libbz2-dev': ensure => present, require => [Exec[apt-update]] }
package { 'default-jre': ensure => present, require => [Exec[apt-update]] }
user { 'build': ensure => present }
file { '/home/build': ensure => directory, owner => build, group => build }
vcsrepo { '/home/build/ghcjs-ghc':
          ensure   => latest,
          provider => git,
          owner => build,
          user => build,
          revision => 'ghc-7.6',
          require => [File['/home/build']]
          # , source   => '/tmp/ghcjs-ghc-repo'
          , source => 'https://github.com/ghcjs/ghc'
        }

file { '/home/build/ghcjs-ghc/dobuild.sh':
     content => "#!/bin/bash
export HOME=/home/build
export LC_ALL=en_US.utf8
(cd /home/build/ghcjs-ghc &&
# ./sync-all -r /tmp/ghcjs-libraries get &&
# ./sync-all -r /tmp/ghcjs-libraries --ghcjs get &&
./sync-all -r https://github.com/ghc get &&
./sync-all -r https://github.com/ghc get &&
./sync-all -r https://github.com/ghc get &&
./sync-all -r https://github.com/ghc get &&
./sync-all -r https://github.com/ghcjs --ghcjs get &&
./sync-all checkout ghc-7.6 &&
cabal update &&
./unpack.sh &&
sed \"s/WORD_SIZE_IN_BITS = 64/WORD_SIZE_IN_BITS = 32/\" libraries/ghcjs/rts/rts-options.js >libraries/ghcjs/rts/rts-options.js.tmp &&
mv libraries/ghcjs/rts/rts-options.js.tmp libraries/ghcjs/rts/rts-options.js &&
./ghcjs-build.sh &&
echo Done) 2>&1| tee /tmp/build.log 
",
     mode => 0755,
     require => Vcsrepo['/home/build/ghcjs-ghc']
     }
# exec { 'unpackghc':
#      command => "/bin/tar -xjf /tmp/install-archives/ghc-7.6.3-i386-unknown-linux.tar.bz2 -C /usr/src",
#      creates => '/usr/src/ghc-7.6.3'
#     }
# exec { 'unpackcabal':
#      command => "/bin/tar -xzf /tmp/install-archives/cabal-install-1.16.0.2.tar.gz -C /usr/src",
#      creates => '/usr/src/cabal-install-1.16.0.2'
#      }
# exec { 'installcabal':
#        command => 'chmod +rx bootstrap.sh && ./bootstrap.sh --global',
#        provider => 'shell',
#        cwd => '/usr/src/cabal-install-1.16.0.2',
#        creates => '/usr/local/bin/cabal',
#        require => [Exec['installghc'], Exec['unpackcabal']]
#      }
file { '/usr/lib/libgmp.so.3':
        ensure => link,
        target => '/usr/lib/i386-linux-gnu/libgmp.so.10'
     }
# exec { 'installghc':
#   command => './configure --prefix=/usr/local && make install',
#   provider => 'shell',
#   cwd => '/usr/src/ghc-7.6.3',
#   creates => '/usr/local/bin/ghc',
#   subscribe => Exec['unpackghc'],
#   require => [Package['ghc'], Package['cabal-install'], File['/usr/lib/libgmp.so.3']]
# }
exec { 'build':
  provider => 'shell',
  timeout => 100000,
  command => "/home/build/ghcjs-ghc/dobuild.sh",
  creates => '/home/build/ghcjs/bin/ghcjs-min',
  subscribe => [Vcsrepo['/home/build/ghcjs-ghc'], File['/home/build/ghcjs-ghc/dobuild.sh']],
  user => build,
  require => [Package['cabal-install'], Package['ghc'],
              Vcsrepo['/home/build/ghcjs-ghc'], File['/home/build/ghcjs-ghc/dobuild.sh'], Package['happy'], Package['autoconf'],
              Package['libtool'], Package['alex'], Package['libbz2-dev'], Package['darcs'], Package['libncurses5-dev']]
}
