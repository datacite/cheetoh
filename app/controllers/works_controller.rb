class WorksController < ApplicationController
  before_action :load_id, except: [:mint]
  before_action :authenticate_user_with_basic_auth!, except: [:show]

  def show
    @work = Work.new(input: @id, from: "datacite")
    fail AbstractController::ActionNotFound unless @work.valid?

    render plain: @work.hsh.to_anvl
  end

  def mint
    input = generate_random_doi(params[:id])

    fail IdentifierError, "A required parameter is missing" unless
      safe_params[:datacite].present? &&
      safe_params[:_target].present?

    @work = Work.new(input: input, from: "datacite")
    fail IdentifierError, "#{params[:id]} has already been registered" if

    input = safe_params[:datacite].anvlunesc

    @work = Work.new(input: input, from: "datacite")
    fail IdentifierError, "metadata could not be validated" unless @work.valid?

    message, status = @work.upsert(username: @username,
                                   password: @password,
                                   url: safe_params[:_target],
                                   data: safe_params[:datacite])

    render plain: message, status: status
  end

  def create
    fail IdentifierError, "A required parameter is missing" unless
      safe_params[:datacite].present? &&
      safe_params[:_target].present?

    @work = Work.new(input: @id, from: "datacite")
    fail IdentifierError, "#{params[:id]} has already been registered" if @work.exists?

    input = safe_params[:datacite].anvlunesc

    @work = Work.new(input: input, from: "datacite")
    fail IdentifierError, "metadata could not be validated" unless @work.valid?

    message, status = @work.upsert(username: @username,
                                   password: @password,
                                   url: safe_params[:_target],
                                   data: safe_params[:datacite])

    render plain: message, status: status
  end

  def update
    if safe_params[:datacite].present?
      input = safe_params[:datacite].anvlunesc
    else
      input = @id
    end

    @work = Work.new(input: input, from: "datacite")
    fail IdentifierError, "metadata could not be validated" unless @work.valid?

    message, status = @work.upsert(username: @username,
                                   password: @password,
                                   url: safe_params[:_target],
                                   data: safe_params[:datacite])

    render plain: message, status: status
  end

  def delete
    render plain: "error: " + "#{params[:id]} is not a reserved DOI", status: 400
  end

  protected

  # id can be DOI or DOI expressed as URL
  def load_id
    @id = normalize_id(params[:id])
    fail AbstractController::ActionNotFound unless @id.present?
  end

  private

  def safe_params
    params.permit(:id, :_target, :_export, :datacite).merge(request.raw_post.from_anvl)
  end
end
