class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        JWT::DecodeError,
                        JWT::VerificationError,
                        IdentifierError,
                        NotImplementedError,
                        AbstractController::ActionNotFound,
                        ActionController::RoutingError,
                        ActionController::ParameterMissing,
                        ActionController::UnpermittedParameters,
                        NoMethodError]

SUPPORTED_PROFILES = {
  datacite: "application/vnd.datacite.datacite+xml", 
  bibtex: "application/x-bibtex",
  ris: "application/x-research-info-systems",
  schema_org: "application/vnd.schemaorg.ld+json",
  citeproc: "application/vnd.citationstyles.csl+json"
}
