use Mix.Config

config :alexa_verifier,
  verifier_client: AlexaVerifier.VerifierClientMock

config :plug,
  validate_header_keys_during_test: false
