# frozen_string_literal: true

require_relative 'lib/ledger_sync/domains/version'

Gem::Specification.new do |spec|
  spec.name          = 'ledger_sync-domains'
  spec.version       = LedgerSync::Domains::VERSION
  spec.authors       = ['Jozef Vaclavik']
  spec.email         = ['jozef@dropbot.sh']

  spec.summary       = 'LedgerSync for Domains/Engines'
  spec.description   = 'Use LedgerSync Operations and Serializers for cross-domain communication.'
  spec.homepage      = 'https://engineering.dropbot.sh'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.2')

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sandbite/ledger_sync-domains'
  spec.metadata['changelog_uri'] = 'https://github.com/sandbite/ledger_sync-domains/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ledger_sync', '~> 2.5.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'factory_bot'
end
