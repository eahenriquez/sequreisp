# Sequreisp - Copyright 2010, 2011 Luciano Ruete
#
# This file is part of Sequreisp.
#
# Sequreisp is free software: you can redistribute it and/or modify
# it under the terms of the GNU Afero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Sequreisp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Afero General Public License for more details.
#
# You should have received a copy of the GNU Afero General Public License
# along with Sequreisp.  If not, see <http://www.gnu.org/licenses/>.

class ContractsController < ApplicationController
  before_filter :require_user
  permissions :contracts
  permissions :arping_mac_address, :only => :arping_mac_address
  # GET /contracts
  # GET /contracts.xml
  def index
    per_page = 30
    params[:search] ||= {}
    # delete proxy_arp boolean condition unless it is true
    # that results in a more intuitive behavior
    params[:search].delete("proxy_arp_is") if params[:search]["proxy_arp_is"] == "0"
    params[:search].delete("is_connected") if params[:search]["is_connected"] == "0"
    per_page = Contract.count if params[:search][:not_paged].present?
    params[:search][:order] ||= 'ascend_by_ip_custom'
    params[:search].delete(:not_paged)
    params[:search][:current_traffic_data_count_less_than] = (params[:search][:current_traffic_data_count_less_than].to_f * 2**30) if params[:search][:current_traffic_data_count_less_than].present?
    params[:search][:current_traffic_data_count_greater_than] = (params[:search][:current_traffic_data_count_greater_than].to_f * 2**30) if params[:search][:current_traffic_data_count_greater_than].present?

    @search = Contract.search(params[:search])
    @contracts = @search.paginate(:page => params[:page],:per_page => per_page)

    @search.current_traffic_data_count_less_than = (@search.current_traffic_data_count_less_than.to_f / 2**30) if @search.current_traffic_data_count_less_than.present?
    @search.current_traffic_data_count_greater_than = (@search.current_traffic_data_count_greater_than.to_f / 2**30) if @search.current_traffic_data_count_greater_than.present?

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contracts }
    end
  end

  def excel
    params[:search] ||= {}
    # delete proxy_arp boolean condition unless it is true
    # that results in a more intuitive behavior
    params[:search].delete("proxy_arp_is") if params[:search]["proxy_arp_is"] == "0"
    params[:search][:order] ||= 'ascend_by_ip_custom'
    @contracts = Contract.search(params[:search])

    # send it to the browsah
    send_data Contract.to_csv(@contracts),
            :type => 'text/csv; charset=UTF-8; header=present',
            :disposition => "attachment; filename=sequreisp_contracts_#{Time.now.strftime("%Y-%m-%d")}.csv"
  end
  # GET /contracts/1
  # GET /contracts/1.xml
  def show
    @contract = object
    render :action => "edit"
  end

  # GET /contracts/new
  # GET /contracts/new.xml
  def new
    @contract = Contract.new
    @contract.client_id = params[:client_id] unless params[:client_id].nil?
    @contract.ceil_dfl_percent = 70

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contract }
    end
  end

  # GET /contracts/1/edit
  def edit
    @contract = object
  end

  # POST /contracts
  # POST /contracts.xml
  def create
    @contract = Contract.new(params[:contract])

    respond_to do |format|
      if @contract.save
        flash[:notice] = t 'controllers.successfully_created'
        format.html { redirect_back_from_edit_or_to(contracts_path) }
        format.xml  { render :xml => @contract, :status => :created, :location => @contract }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contract.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contracts/1
  # PUT /contracts/1.xml
  def update
    @contract = object

    respond_to do |format|
      if @contract.update_attributes(params[:contract])
        flash[:notice] = t 'controllers.successfully_updated'
        format.html { redirect_back_from_edit_or_to(contracts_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contract.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contracts/1
  # DELETE /contracts/1.xml
  def destroy
    @contract = object
    @contract.destroy

    respond_to do |format|
      format.html { redirect_back_from_edit_or_to contracts_url }
      format.xml  { head :ok }
    end
  end

  def massive
    if params[:contracts_ids].present?
      @contracts = Contract.find(params[:contracts_ids])
      if params.has_key? :massive_update
        delete_params_blank_in_massive_setting
        massive_update
      elsif params.has_key? :massive_destroy
        massive_destroy
      end
    else
      flash[:warning] = t('error_messages.not_selected_contracts')
    end
    redirect_back_from_edit_or_to(contracts_path)
  end

  def massive_destroy
    if @contracts.map(&:destroy)
      flash[:notice] = t 'controllers.successfully_deleted'
    else
      flash[:error] = t 'controllers.unsuccessfully_deleted'
    end
  end

  def massive_update
    unless params[:massive_setting].empty?
      errors = []
      applied = []
      if params[:massive_setting][:client_name].present?
        params[:massive_setting][:client_id] = Client.find_by_name(params[:massive_setting][:client_name]).id
        params[:massive_setting].delete(:client_name)
      end
      params[:massive_setting][:plan_id] = params[:massive_setting][:plan] if params[:massive_setting][:plan].present?
      params[:massive_setting].delete(:plan) if params[:massive_setting][:plan].present?

      @contracts.each do |contract|
        if contract.update_attributes(params[:massive_setting])
          applied << contract.id
        else
          errors << "#{Contract.human_name} id #{contract.id}: #{contract.errors.full_messages.to_sentence}"
        end
      end
      flash[:notice] = t('messages.contracts_with_id_was_updated_successfully', {:ids => applied.join(", ")}) if not applied.empty?
      flash[:error] = errors.join(",") if not errors.empty?
    else
      flash[:warning] = t('error_messages.not_selected_any_options')
    end
  end

  def instant
    @contract = object
    respond_to do |format|
      format.json { render :json => @contract.instant }
    end
  end

  def free_ips
    respond_to do |format|
      format.json { render :json => Contract.free_ips(params[:term])[0..9] }
    end
  end
  def ips
    respond_to do |format|
      format.json { render :json => Contract.all(:conditions => ["ip like ?", "%#{params[:term]}%"], :limit => 10, :select => :ip).collect(&:ip) }
    end
  end
  def arping_mac_address
    # arping will be excecuted by sudo, let's enshure that only an ip address is submited
    c = Contract.new(:ip => params[:ip])
    mac_address = (IP.new(params[:ip]) rescue nil).nil? ? nil : c.arping_mac_address
    respond_to do |format|
      format.json { render :json => {:mac_address => mac_address} }
    end
  end
  def graph
    @graph = Graph.new(:class => object.class.name, :id => object.id)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @graph }
    end
  end
  private
  def object
    @object ||= Contract.find(params[:id])
  end
end
