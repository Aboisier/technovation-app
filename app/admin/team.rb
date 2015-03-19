ActiveAdmin.register Team do
  config.clear_action_items!

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  index do
    selectable_column
    column :name
    column :region
    column :country do |team|
      ISO3166::Country[team.country]
    end
    column :division
    column :year

    column :event_id do |t|
      unless t.event_id.nil?
        link_to Event.find(t.event_id).name, admin_event_path(t.event_id)
      end
    end

    column (:rubrics_count){|t| t.rubrics.length}
    column (:rubrics_average){|t| 
      scores = t.rubrics.map{|r| r.score}
      scores.inject(:+).to_f / scores.size
      }

    column :issemifinalist
    column :isfinalist
    column :iswinner

    actions
  end

  filter :name
  filter :region, as: :select, collection: Team.regions.keys
  filter :country, as: :select, collection: ActionView::Helpers::FormOptionsHelper::COUNTRIES
  filter :division, as: :select, collection: Team.divisions.keys
  filter :year
  preserve_default_filters!

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs "Team Details" do
      f.input :name
      f.input :about
      f.input :year
      f.input :avatar, as: :file, required: false
# <<<<<<< HEAD
#       f.input :region, as: :select, collection: Event.regions.keys
# #      f.input :event, as: :select, collection: Event.all
# =======
      f.input :region, as: :select, collection: Team.regions.keys
      f.input :division, as: :select, collection: Team.divisions.keys
      f.input :country, as: :country
    end
    f.actions
  end


  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #   permitted = [:permitted, :attributes]
  #   permitted << :other if resource.something?
  #   permitted
  # end


end
