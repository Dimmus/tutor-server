class RenameCatalogOfferingsIdentifierToSalesforceBookNameAndAddAppearanceCode < ActiveRecord::Migration
  def change
    rename_column :catalog_offerings, :identifier, :salesforce_book_name
    add_column :catalog_offerings, :appearance_code, :string

    reversible do |dir|
      dir.up { Catalog::Models::Offering.update_all('"appearance_code" = "salesforce_book_name"') }
    end
  end
end
