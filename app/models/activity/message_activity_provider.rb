#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Activity::MessageActivityProvider < Activity::BaseActivityProvider

  acts_as_activity_provider type: 'messages',
                            permission: :view_messages

  def extend_event_query(query)
    query.join(boards_table).on(activity_journals_table[:board_id].eq(boards_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:subject, 'message_subject'),
      activity_journal_projection_statement(:content, 'message_content'),
      activity_journal_projection_statement(:parent_id, 'message_parent_id'),
      projection_statement(boards_table, :id, 'board_id'),
      projection_statement(boards_table, :name, 'board_name'),
      projection_statement(boards_table, :project_id, 'project_id')
    ]
  end

  def projects_reference_table
    boards_table
  end

  protected

  def event_title(event)
    "#{event['board_name']}: #{event['message_subject']}"
  end

  def event_description(event)
    event['message_content']
  end

  def event_type(event)
    event['parent_id'].blank? ? 'message' : 'reply'
  end

  def event_path(event)
    Rails.application.routes.url_helpers.topic_path(url_helper_parameter(event))
  end

  def event_url(event)
    Rails.application.routes.url_helpers.topic_url(url_helper_parameter(event),
                                                   host: ::Setting.host_name)
  end

  private

  def boards_table
    @boards_table ||= Arel::Table.new(:boards)
  end

  def url_helper_parameter(event)
    is_reply = !event['parent_id'].blank?

    if is_reply
      parameters = { id: event['parent_id'], r: event['journable_id'], anchor: "message-#{event['journable_id']}" }
    else
      parameters = { id: event['journable_id'] }
    end

    parameters[:board_id] = event['board_id']
    parameters
  end
end
