class WorksController < ApplicationController
  prepend_before_action :authenticate_user_with_basic_auth!, except: [:show]
  before_action :load_id, except: [:mint]
  before_action :set_profile

  SUPPORTED_PROFILES = [:datacite, :crossref, :bibtex, :ris, :schema_org, :citeproc]

  def show
    @work = Work.new(input: @id, from: "datacite", format: @profile)
    fail AbstractController::ActionNotFound unless @work.valid?

    render plain: @work.hsh.to_anvl
  end

  def mint
    fail IdentifierError, "A required parameter is missing" unless
      safe_params[@profile].present? && safe_params[:_target].present?

    # make sure we generate a random DOI that is not already used
    # allow seed with number for deterministic minting
    if safe_params[:_number].present?
      @id = generate_random_doi(params[:id], number: safe_params[:_number])
      @work = Work.new(input: @id, from: @profile.to_s)
      fail IdentifierError, "#{@id} has already been registered" if
        @work.exists? && !Rails.env.test?
    else
      duplicate = true
      while duplicate do
        @id = generate_random_doi(params[:id])
        @work = Work.new(input: @id, from: @profile.to_s)
        duplicate = @work.exists?
      end
    end

    input = safe_params[@profile].anvlunesc
    doi = doi_from_url(@id)

    @work = Work.new(input: input,
                     from: @profile.to_s,
                     doi: doi,
                     target: safe_params[:_target],
                     data: safe_params[@profile])
    fail IdentifierError, "metadata could not be validated" unless @work.valid?
    fail IdentifierError, "params doi:#{doi} does not match doi:#{@work.doi} in metadata" unless
      doi == @work.doi

    message, status = @work.upsert(username: @username,
                                   password: @password)

    render plain: message, status: status
  end

  def create
    fail IdentifierError, "A required parameter is missing" unless
      safe_params[@profile].present? && safe_params[:_target].present?

    @work = Work.new(input: @id, from: "datacite")
    fail IdentifierError, "#{params[:id]} has already been registered" if @work.exists?

    input = safe_params[@profile].anvlunesc

    @work = Work.new(input: input,
                     from: @profile.to_s,
                     doi: doi_from_url(@id),
                     target: safe_params[:_target],
                     data: safe_params[@profile])
    fail IdentifierError, "metadata could not be validated" unless @work.valid?
    fail IdentifierError, "params #{params[:id]} does not match #{@work.doi_with_protocol} in metadata" unless
      params[:id] == @work.doi_with_protocol

    message, status = @work.upsert(username: @username,
                                   password: @password)

    render plain: message, status: status
  end

  def update
    fail IdentifierError, "A required parameter is missing" unless
      safe_params[@profile].present? || safe_params[:_target].present?

    if safe_params[@profile].present?
      input = safe_params[@profile].anvlunesc
    else
      input = @id
    end

    @work = Work.new(input: input,
                     from: @profile.to_s,
                     target: safe_params[:_target],
                     data: safe_params[@profile])

    fail IdentifierError, "metadata could not be validated" unless @work.valid?
    fail IdentifierError, "params #{params[:id]} does not match #{@work.doi_with_protocol} in metadata" unless
      params[:id] == @work.doi_with_protocol

    message, status = @work.upsert(username: @username,
                                   password: @password)

    render plain: message, status: status
  end

  def delete
    render plain: "error: " + "#{params[:id]} is not a reserved DOI", status: 400
  end

  protected

  # id can be DOI or DOI expressed as URL
  def load_id
    @id = normalize_id(params[:id])
    fail IdentifierError, "ark identifiers are not supported by this service" if is_ark?(params[:id])
    fail AbstractController::ActionNotFound unless @id.present?
  end

  def set_profile
    @profile = safe_params[:_profile].presence || :datacite
    fail IdentifierError, "#{safe_params[:_profile]} profile not supported by this service" unless
      SUPPORTED_PROFILES.include?(@profile.to_sym)
  end

  private

  def safe_params
    params.permit(:id, :_target, :_export, :_profile, :_number, :datacite, :crossref, :bibtex, :ris, :schema_org, :citeproc).merge(request.raw_post.from_anvl)
  end
end
