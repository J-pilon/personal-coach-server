class AddOnboardingVersionToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :onboarding_version, :string
  end
end
