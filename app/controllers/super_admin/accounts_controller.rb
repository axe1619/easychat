require 'csv'

class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  def resource_params
    permitted_params = super
    permitted_params[:limits] = permitted_params[:limits].to_h.compact
    permitted_params[:selected_feature_flags] = params[:enabled_features].keys.map(&:to_sym) if params[:enabled_features].present?
    permitted_params
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def seed
    Internal::SeedAccountJob.perform_later(requested_resource)
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account seeding triggered')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def reset_cache
    requested_resource.reset_cache_keys
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Cache keys cleared')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def destroy
    account = Account.find(params[:id])

    DeleteObjectJob.perform_later(account) if account.present?
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account deletion is in progress.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def export
    resources = scoped_resource
    resources = filter_by_status(resources)
    resources = resources.includes(account_users: :user) if csv_attributes.include?(:email)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << csv_headers
      resources.each do |resource|
        csv << csv_attributes.map { |attribute| csv_value(resource, attribute) }
      end
    end

    timestamp = Time.zone.now.strftime('%Y%m%d-%H%M%S')
    csv_with_bom = "\uFEFF#{csv_data}"
    send_data csv_with_bom,
              filename: "accounts-#{timestamp}.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  private

  def csv_attributes
    %i[id name email status created_at]
  end

  def csv_headers
    csv_attributes.map do |attribute|
      I18n.t(
        "helpers.label.#{resource_name}.#{attribute}",
        default: resource_class.human_attribute_name(attribute).titleize
      )
    end
  end

  def csv_value(resource, attribute)
    value = resource.public_send(attribute)
    return value.count if value.respond_to?(:count) && !value.is_a?(String)

    value
  end


  def filter_by_status(resources)
    return resources if params[:status].blank?

    status = params[:status].to_s
    return resources.where(status: status) if Account.statuses.key?(status)

    resources
  end
end
