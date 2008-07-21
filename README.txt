= jabber_component_framework

== WARNING

This component was originally developed by Geni.com for a specialized product called Workfeed.   The eventual goal is to have this framework be easily reusable, however, right now it still relies on assumptions about the workfeed product including the existence of a JabberRosterItem AR model, an active Starling queue, as well as memcache.   The goal is to abstract those workfeed dependencies shortly.

== DESCRIPTION:

The jabber component framework is meant to be a general purpose framework for creating xmpp bots or services using the xmpp component system.   It is meant to be a lot like xmpp4r-simple (and relies on xmpp4r), but for components.

Components are often more desirable than straight clients because of the additional functionality you get with components including:

* Ability to manage your own roster and presence caches
* Ability to run multiple instances of the component where your jabber servers sends all messages to your running instances via round robin
* The presence of your component is controlled by you.  So, for example, you can restart your component without going 'offline'

These are just a few of the benefits of using a component.

The downside is that your jabber server will not keep track of subscriptions/rosters/presence for you.  It is up to the component to do that.   This component framework comes with proxies for doing just that.

== FEATURES/PROBLEMS:

* Manages subscriptions
* Manages presence (for multiple resources per JID)
* Manages rosters
* Automatically send a subscription request when attempting to send a message to a user who you are not subscribed to.  Message is deferred until subscription confirmation is returned, at which point the original message is sent.

== REQUIREMENTS:

* Starling
* Memcache - You must set the global constant CACHE to your memcache client (we will be removing this dependency)
* JabberRosterItem AR model with at least 2 fields, subscription, and jid  

The current script/jabber_component request ICanDaemonize http://github.com/geni/i_can_daemonize/tree/master

== INSTALL:

* FIX (sudo gem install, anything else)
At the moment, if you are using this within a RAILS app, it expects you will install this gem into /vendor/gems/

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIXME full name

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.