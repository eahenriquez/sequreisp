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

module ContractsHelper
  def client_name_plus_external_client_number_and_detail_cpe_node_label
    "#{t('activerecord.attributes.client.name')} " +
    "| #{t('activerecord.attributes.client.external_client_number')} " +
    "(#{t('activerecord.attributes.contract.detail')}/" +
    "#{t('activerecord.attributes.contract.cpe')}/" +
    "#{t('activerecord.attributes.contract.node')})"
  end
  def external_client_number_and_detail_cpe_node(contract)
    value = "| #{contract.client.client_number} "
    if not contract.detail.blank? or not contract.cpe.blank? or not contract.node.blank?
      value += "(#{contract.detail}/#{contract.cpe}/#{contract.node})"
    end
    value
  end
  def contract_ip_link(ip)
    link_to '<span class="ui-icon ui-icon-newwin" style="display: inline-block"></span>', "http://#{ip}/", :target => "_blank"
  end
end
