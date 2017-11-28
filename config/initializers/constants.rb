class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [CanCan::AccessDenied,
                        JWT::DecodeError,
                        JWT::VerificationError,
                        IdentifierError,
                        AbstractController::ActionNotFound,
                        ActionController::RoutingError,
                        ActionController::ParameterMissing,
                        ActionController::UnpermittedParameters,
                        NoMethodError]
