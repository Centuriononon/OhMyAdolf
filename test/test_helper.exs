Mox.defmock(OhMyAdolf.HTTPClientMock, for: HTTPoison.Base)
Mox.defmock(OhMyAdolf.Wiki.WikiURLMock, for: OhMyAdolf.Wiki.Behaviors.WikiURLBehavior)

ExUnit.start()
