# AlexaVerifier

## Checking the Signature of the Request

Requests sent by Alexa provide the information you need to verify the signature in the HTTP headers:

- SignatureCertChainUrl
- Signature

To validate the signature:

1. Verify the URL specified by the SignatureCertChainUrl header value on the request to ensure that it matches the format used by Amazon. See Verifying the Signature Certificate URL.

1. Download the PEM-encoded X.509 certificate chain that Alexa used to sign the message as specified by the SignatureCertChainUrl header value on the request.

This chain is provided at runtime so that the certificate may be updated periodically, so your web service should be resilient to different URLs with different content.

1. This certificate chain is composed of, in order, (1) the Amazon signing certificate and (2) one or more additional certificates that create a chain of trust to a root certificate authority (CA) certificate. To confirm the validity of the signing certificate, perform the following checks:
- The signing certificate has not expired (examine both the Not Before and Not After dates)
- The domain echo-api.amazon.com is present in the Subject Alternative Names (SANs) section of the signing certificate
- All certificates in the chain combine to create a chain of trust to a trusted root CA certificate

1. Once you have determined that the signing certificate is valid, extract the public key from it.

1. Base64-decode the Signature header value on the request to obtain the encrypted signature.

1. Use the public key extracted from the signing certificate to decrypt the encrypted signature to produce the asserted hash value.

1. Generate a SHA-1 hash value from the full HTTPS request body to produce the derived hash value

1. Compare the asserted hash value and derived hash values to ensure that they match.

## Verifying the Signature Certificate URL

Before downloading the certificate from the URL specified in the SignatureCertChainUrl header, you should ensure that the URL represents a URL Amazon would use for the certificate. This protects against requests that attempt to make your web service download malicious files and similar attacks.

First, normalize the URL so that you can validate against a correctly formatted URL. For example, normalize

https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem

to:

https://s3.amazonaws.com/echo.api/echo-api-cert.pem

Next, determine whether the URL meets each of the following criteria:

- The protocol is equal to https (case insensitive).
- The hostname is equal to s3.amazonaws.com (case insensitive).
- The path starts with /echo.api/ (case sensitive).
- If a port is defined in the URL, the port is equal to 443.

Examples of correctly formatted URLs:

- https://s3.amazonaws.com/echo.api/echo-api-cert.pem
- https://s3.amazonaws.com:443/echo.api/echo-api-cert.pem
- https://s3.amazonaws.com/echo.api/../echo.api/echo-api-cert.pem

Examples of invalid URLs:

- http://s3.amazonaws.com/echo.api/echo-api-cert.pem (invalid protocol)
- https://notamazon.com/echo.api/echo-api-cert.pem (invalid hostname)
- https://s3.amazonaws.com/EcHo.aPi/echo-api-cert.pem (invalid path)
- https://s3.amazonaws.com/invalid.path/echo-api-cert.pem (invalid path)
- https://s3.amazonaws.com:563/echo.api/echo-api-cert.pem (invalid port)

If the URL does not pass these tests, reject the request and do not proceed with verifying the signature.


## TODO

- [ ] Add better parsing of the cert info such as the issuer and subject.
- [ ] All certificates in the chain combine to create a chain of trust to a trusted root CA certificate
- [x] Once you have determined that the signing certificate is valid, extract the public key from it.
- [x] Base64-decode the Signature header value on the request to obtain the encrypted signature.
- [ ] Use the public key extracted from the signing certificate to decrypt the encrypted signature to produce the asserted hash value.
- [ ] Generate a SHA-1 hash value from the full HTTPS request body to produce the derived hash value
- [ ] Compare the asserted hash value and derived hash values to ensure that they match.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `alexa_verifier` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:alexa_verifier, "~> 0.1.0"}]
    end
    ```

  2. Ensure `alexa_verifier` is started before your application:

    ```elixir
    def application do
      [applications: [:alexa_verifier]]
    end
    ```
