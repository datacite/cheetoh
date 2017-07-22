class IdController < ApplicationController
  before_action :load_id, only: [:show]

  def show
    @metadata = Metadata.new(input: @id, from: "datacite")
    fail AbstractController::ActionNotFound unless @metadata.valid?

    render plain: @metadata.to_anvl
  end

  protected

  # id can be DOI or DOI expressed as URL
  def load_id
    @id = normalize_id(params[:id])
    fail AbstractController::ActionNotFound unless @id.present?
  end
end
