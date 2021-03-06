module Backend
  # Manage PlantDensityAbacus records
  class PlantDensityAbaciController < Backend::BaseController
    manage_restfully

    list do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: { action: :edit }
    end
  end
end
