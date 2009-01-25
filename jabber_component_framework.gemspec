Gem::Specification.new do |s|
  s.name = %q{jabber_component_framework}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Pisoni"]
  s.date = %q{2009-01-25}
  s.description = %q{TODO}
  s.email = %q{apisoni@geni.com}
  s.files = ["VERSION.yml", "lib/jabber_component_framework", "lib/jabber_component_framework/component_jid.rb", "lib/jabber_component_framework/controller.rb", "lib/jabber_component_framework/jid_extensions.rb", "lib/jabber_component_framework/jid_presence.rb", "lib/jabber_component_framework/message_queue_adapters", "lib/jabber_component_framework/message_queue_adapters/abstract_adapter.rb", "lib/jabber_component_framework/message_queue_adapters/starling.rb", "lib/jabber_component_framework/presence_adapters", "lib/jabber_component_framework/presence_adapters/abstract_adapter.rb", "lib/jabber_component_framework/presence_adapters/memory.rb", "lib/jabber_component_framework/roster.rb", "lib/jabber_component_framework/roster_adapters", "lib/jabber_component_framework/roster_adapters/abstract_adapter.rb", "lib/jabber_component_framework/roster_adapters/memory.rb", "lib/jabber_component_framework/roster_item.rb", "lib/jabber_component_framework.rb", "lib/queue_proxy.rb", "lib/queue_proxy_mock.rb", "test/client_tester.rb", "test/test_helper.rb", "test/test_jabber_component_framework.rb", "test/test_roster.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/wonko9/jabber_component_framework}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{TODO}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
