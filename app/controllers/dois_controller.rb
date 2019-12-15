class DoisController < ApplicationController
  include Doiable

  prepend_before_action :authenticate_user_with_basic_auth!, except: [:show]
  before_action :set_profile
  before_action :set_doi, only: [:show, :update, :destroy]
  before_action :set_raven_context, only: [:mint, :create, :update]

  def show
    response = DoisController.get_doi(@doi)

    if response.status == 200
      render plain: ez_response(response.body, profile: @profile).to_anvl, status: :ok
    elsif response.status == 404
      render plain: "error: bad request - no such identifier", status: :bad_request
    else
      logger.error response.body.dig("errors", 0, "title")
      render plain: "error: " + response.body.dig("errors", 0, "title"), status: response.status
    end
  end

  def mint
    fail IdentifierError, "no _profile provided" unless profile_present?(safe_params)
    fail IdentifierError, "no _target provided" if (safe_params[:_target].blank? && safe_params[:_status] != "reserved")

    # make sure we generate a random DOI that is not already used
    # allow seed with number for deterministic minting (e.g. testing)
    if safe_params[:_number].present?
      doi = generate_random_doi(params[:id], number: safe_params[:_number])

      fail IdentifierError, "doi:#{doi} has already been registered" if DoisController.get_doi(doi).status == 200
    else
      duplicate = true
      while duplicate do
        doi = generate_random_doi(params[:id])
        duplicate = DoisController.get_doi(doi).status == 200
      end
    end

    data = safe_params[@profile].present? ? URI.decode(safe_params[@profile].anvlunesc) : nil

    options = {
      data: data,
      url: safe_params[:_target],
      target_status: safe_params[:_status],
      username: @username,
      password: @password }

    options = datacite_options(options) if @profile.to_s == "datacite"
    response = DoisController.post_doi(doi, options)

    if [200, 201].include?(response.status)
      render plain: ez_response(response.body, profile: @profile).to_anvl, status: :ok
    elsif [401, 403].include?(response.status)
      response.headers.delete_if { |key| key == 'X-Credential-Username' }
      render plain: "error: unauthorized", status: :unauthorized
    else
      logger.error response.body.dig("errors", 0, "title")
      render plain: "error: " + response.body.dig("errors", 0, "title"), status: response.status
    end
  end

  def create
    doi = validate_doi(params[:id])
    fail IdentifierError, "ark identifiers are not supported by this service" if is_ark?(params[:id])
    fail IdentifierError, "no doi provided" unless doi.present?
    fail IdentifierError, "no _profile provided" unless profile_present?(safe_params)
    fail IdentifierError, "no _target provided" if
      (safe_params[:_target].blank? && safe_params[:_status] != "reserved")
    fail IdentifierError, "doi:#{doi} has already been registered" if DoisController.get_doi(doi).status == 200

    data = decode_param(safe_params[@profile])

    options = {
      data: data,
      url: decode_param(safe_params[:_target]),
      target_status: safe_params[:_status],
      username: @username,
      password: @password }.compact

    options = datacite_options(options) if @profile.to_s == "datacite"
    response = DoisController.post_doi(doi, options)

    if [200, 201].include?(response.status)
      render plain: ez_response(response.body, profile: @profile).to_anvl, status: :ok
    elsif [401, 403].include?(response.status)
      response.headers.delete_if { |key| key == 'X-Credential-Username' }
      render plain: "error: unauthorized", status: :unauthorized
    else
      logger.error response.body.dig("errors", 0, "title")
      render plain: "error: " + response.body.dig("errors", 0, "title"), status: response.status
    end
  end

  def update
    fail IdentifierError, "No _profile, _target or _status provided" unless
      safe_params[@profile].present? ||
      safe_params[:_target].present? ||
      safe_params[:_status].present?

    data = decode_param(safe_params[@profile])

    options = {
      data: data,
      url: decode_param(safe_params[:_target]),
      target_status: safe_params[:_status],
      username: @username,
      password: @password }.compact

    options = datacite_options(options) if @profile.to_s == "datacite"
    response = DoisController.put_doi(@doi, options)

    if [200, 201].include?(response.status)
      render plain: ez_response(response.body, profile: @profile).to_anvl, status: :ok
    elsif [401, 403].include?(response.status)
      response.headers.delete_if { |key| key == 'X-Credential-Username' }
      render plain: "error: unauthorized", status: :unauthorized
    else
      logger.error response.body.dig("errors", 0, "title")
      render plain: "error: " + response.body.dig("errors", 0, "title"), status: response.status
    end
  end

  def destroy
    response = DoisController.get_doi(@doi)
    fail AbstractController::ActionNotFound unless response.status == 200
    fail IdentifierError, "#{params[:id]} is not a reserved DOI" unless response.body.dig("data", "attributes", "state") == "draft"

    delete_response = DoisController.delete_doi(@doi, username: @username, password: @password)

    if delete_response.status == 204
      render plain: ez_response(response.body, profile: @profile).to_anvl, status: :ok
    elsif [401, 403].include?(delete_response.status)
      delete_response.headers.delete_if { |key| key == 'X-Credential-Username' }
      render plain: "error: unauthorized", status: :unauthorized
    else
      logger.error delete_response.body.dig("errors", 0, "title")
      render plain: "error: " + delete_response.body.dig("errors", 0, "title"), status: response.status
    end
  end

  protected

  def set_doi
    fail IdentifierError, "ark identifiers are not supported by this service" if is_ark?(params[:id])

    @doi = validate_doi(params[:id])
    fail AbstractController::ActionNotFound unless @doi.present?
  end

  def profile_present?(safe_params)
    safe_params[:_status] == "reserved" ||
    safe_params[@profile].present? ||
    safe_params["datacite.creator"].present? &&
    safe_params["datacite.title"].present? &&
    safe_params["datacite.publisher"].present? &&
    safe_params["datacite.publicationyear"].present? &&
    safe_params["datacite.resourcetype"].present? 
  end

  def set_profile
    @profile = safe_params[:_profile].presence || :datacite
    fail IdentifierError, "#{safe_params[:_profile]} profile not supported by this service" unless
      SUPPORTED_PROFILES[@profile.to_sym].present?
  end

  private

  def safe_params
    params.permit(:id, :_target, :_export, :_profile, :_status, :_number, :datacite, :bibtex, :ris, :schema_org, :citeproc, "datacite.creator", "datacite.title", "datacite.publisher", "datacite.publicationyear", "datacite.resourcetype")
  end

  def set_raven_context
    return nil unless safe_params[@profile].present?

    Raven.extra_context metadata: URI.escape(safe_params[@profile])
  end
  
  def datacite_options(options)
    resource_type_general, resource_type = decode_param(safe_params["datacite.resourcetype"])&.split('/')
    options = options.merge(
      creator: decode_param(safe_params["datacite.creator"]),
      title: decode_param(safe_params["datacite.title"]),
      publisher: decode_param(safe_params["datacite.publisher"]),
      publication_year: decode_param(safe_params["datacite.publicationyear"]),
      resource_type_general: resource_type_general,
      resource_type: resource_type
    ) 
  end
end
