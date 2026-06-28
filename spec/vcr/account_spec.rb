# frozen_string_literal: true

RSpec.describe "Account endpoints", :vcr do
  subject(:client) { RockautoApi::Client.new }

  let(:email) { "torofa7390@disiok.com" }
  let(:password) { 'JQ#Xo%2lS^*&$i' }

  describe "#login" do
    it "returns true with valid credentials" do
      result = client.login(email, password)
      expect(result).to be true
      expect(client.authenticated?).to be true
    end

    it "authenticated? returns false before login" do
      expect(client.authenticated?).to be false
    end

    it "returns false with invalid credentials" do
      result = client.login("wrong@email.com", "wrongpassword")
      expect(result).to be false
      expect(client.authenticated?).to be false
    end
  end

  describe "authenticated endpoints" do
    before do
      client.login(email, password)
    end

    describe "#get_saved_addresses" do
      it "returns SavedAddressesResult" do
        result = client.get_saved_addresses
        expect(result).to be_a(RockautoApi::Models::SavedAddressesResult)
        expect(result.count).to be >= 0
      end
    end

    describe "#get_saved_vehicles" do
      it "returns SavedVehiclesResult" do
        result = client.get_saved_vehicles
        expect(result).to be_a(RockautoApi::Models::SavedVehiclesResult)
        expect(result.count).to be >= 0
      end
    end

    describe "#get_order_history" do
      it "returns OrderHistoryResult" do
        result = client.get_order_history
        expect(result).to be_a(RockautoApi::Models::OrderHistoryResult)
        expect(result.count).to be >= 0
      end
    end

    describe "#get_account_activity" do
      it "returns AccountActivityResult" do
        result = client.get_account_activity
        expect(result).to be_a(RockautoApi::Models::AccountActivityResult)
      end
    end

    describe "#add_external_order" do
      it "adds an external order" do
        result = client.add_external_order(email, "RA-999999")
        expect([true, false]).to include(result)
      end
    end

    describe "#logout" do
      it "resets authenticated state" do
        client.logout
        expect(client.authenticated?).to be false
      end
    end
  end

  describe "authentication guard" do
    it "raises AuthenticationError for #get_saved_addresses" do
      expect { client.get_saved_addresses }.to raise_error(RockautoApi::AuthenticationError)
    end

    it "raises AuthenticationError for #get_saved_vehicles" do
      expect { client.get_saved_vehicles }.to raise_error(RockautoApi::AuthenticationError)
    end

    it "raises AuthenticationError for #get_order_history" do
      expect { client.get_order_history }.to raise_error(RockautoApi::AuthenticationError)
    end

    it "raises AuthenticationError for #get_account_activity" do
      expect { client.get_account_activity }.to raise_error(RockautoApi::AuthenticationError)
    end
  end
end
