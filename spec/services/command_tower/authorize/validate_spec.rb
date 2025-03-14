# frozen_string_literal: true

RSpec.describe CommandTower::Authorize::Validate do
  before do
    CommandTower::Authorization::Role.roles_reset!
    CommandTower::Authorization::Entity.entities_reset!
    CommandTower::Authorization.default_defined!
  end

  after do
    CommandTower::Authorization::Role.roles_reset!
    CommandTower::Authorization::Entity.entities_reset!
  end

  describe ".call" do
    subject(:call) { described_class.call(user:, controller:, method:) }
    let(:controller) { CommandTower::AdminController }
    let(:method) { "show" }

    let(:user) { create(:user, :role_admin) }

    it "succeeds" do
      expect(call.success?).to be(true)
    end

    it "sets context variables" do
      expect(call.authorization_required).to be(true)
      expect(call.msg).to eq("User is Authorized for action")
    end

    context "with action that does not require authorization" do
      let(:controller) { CommandTower::UsernameController }
      let(:method) { "username_availability" }

      it "succeeds" do
        expect(call.success?).to be(true)
      end

      it "sets context variables" do
        expect(call.authorization_required).to be(false)
        expect(call.msg).to eq("Authorization not required at this time")
      end
    end


    context "when user has multiple conflicting roles with at least 1 authorized" do
      let(:user) { create(:user, :admin_roles) }

      it "succeeds" do
        expect(call.success?).to be(true)
      end

      it "sets context variables" do
        expect(call.authorization_required).to be(true)
        expect(call.msg).to eq("User is Authorized for action")
      end
    end


    context "when user does not have correct authorization" do
      let(:user) { create(:user) }

      it "fails" do
        expect(call.failure?).to be(true)
      end

      it "sets context variables" do
        expect(call.authorization_required).to be(true)
        expect(call.msg).to eq("Unauthorized Access. Incorrect User Privileges")
      end
    end
  end
end
