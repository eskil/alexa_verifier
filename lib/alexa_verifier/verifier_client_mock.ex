defmodule AlexaVerifier.VerifierClientMock do

  def verify(_, "success", _) do
    :ok
  end

  def verify(_, "failure", _) do
    :error
  end

end
