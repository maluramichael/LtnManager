local gui = require("__flib__.gui-new")

local sort_checkbox = require("scripts.gui.main.components.common.sort-checkbox")
local history_row = require("scripts.gui.main.components.history.history-row")

local component = gui.component()

function component.init()
  return {
    selected_sort = "finished",
    sort_depot = true,
    sort_train_id = false,
    sort_network_id = false,
    sort_route = true,
    sort_finished = false,
    sort_runtime = false,
    sort_shipment = false
  }
end

function component.update(state, msg, e)
  if msg.action == "update_sort" then
    local sort = msg.sort
    local history_state = state.history

    if history_state.selected_sort ~= sort then
      e.element.state = not e.element.state
    end

    history_state.selected_sort = sort
    history_state["sort_"..sort] = e.element.state
  end
end

local function generate_history_rows(state)
  local history = state.ltn_data.history
  local history_state = state.history

  -- get station IDs based on active sort
  local selected_sort = history_state.selected_sort
  local history_ids = state.ltn_data.sorted_history[selected_sort]
  local selected_sort_state = history_state["sort_"..history_state.selected_sort]

  -- search
  local search_state = state.search
  local search_query = search_state.query
  local search_network_id = search_state.network_id
  local search_surface = search_state.surface

  -- iteration data
  local start = selected_sort_state and 1 or #history_ids
  local finish = selected_sort_state and #history_ids or 1
  local step = selected_sort_state and 1 or -1

  -- build history rows
  local rows = {}
  local i = 0
  for j = start, finish, step do
    local history_id = history_ids[j]
    local history_data = history[history_id]

    -- test against search queries
    if
      (search_surface == -1 or history_data.surface_index == search_surface)
      and bit32.btest(history_data.network_id, search_network_id)
      and string.find(history_data.search_strings[state.player_index], search_query)
    then
      i = i + 1
      rows[i] = history_row(state, history_data)
    end
  end

  return rows
end

function component.view(state)
  local rows = generate_history_rows(state)

  local gui_constants = state.constants.history
  local history_state = state.history

  return (
    {
      tab = {type = "tab", caption = {"ltnm-gui.history"}},
      content = (
        {type = "frame", style = "deep_frame_in_shallow_frame", direction = "vertical", children = {
          -- toolbar
          {type = "frame", style = "ltnm_table_toolbar_frame", children = {
            sort_checkbox("history", "depot", "depot", nil, history_state, gui_constants),
            sort_checkbox("history", "train_id", "train-id", "train-id", history_state, gui_constants),
            sort_checkbox("history", "network_id", "network-id", "network-id", history_state, gui_constants),
            sort_checkbox("history", "route", "route", nil, history_state, gui_constants),
            sort_checkbox("history", "runtime", "runtime", nil, history_state, gui_constants),
            sort_checkbox("history", "finished", "finished", nil, history_state, gui_constants),
            sort_checkbox("history", "shipment", "shipment", nil, history_state, gui_constants)
          }},
          -- content
          {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = rows}
        }}
      )
    }
  )
end

return component