class Admin::CatalogOfferingCreate
  lev_handler

  paramify :offering do
    attribute :identifier, type: String
    attribute :description, type: String
    attribute :content_ecosystem_id, type: Integer
    attribute :webview_url, type: String
    attribute :pdf_url, type: String

    validates :identifier, :description, :webview_url, :pdf_url, presence: true
  end

  uses_routine Catalog::CreateOffering, as: :create_offering

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    debugger
    run(:create_offering, offering_params.as_json)
  end
end
