module 'aux.tabs.search'

local T = require 'T'
local aux = require 'aux'
local info = require 'aux.util.info'
local filter_util = require 'aux.util.filter'
local gui = require 'aux.gui'

local buy_list_editor = {
	name = '',
	items = {},
	edit_index = nil,
}

selected_buy_list_index = nil

function aux.handle.LOAD()
	recent_searches = aux.realm_data.recent_searches
	favorite_searches = aux.realm_data.favorite_searches
	shopping_lists = aux.realm_data.shopping_lists
end

local function normalize_item_name(name)
	name = aux.trim(name or '')
	if name == '' then
		return nil
	end
	local item_id = info.item_id(name)
	if item_id then
		local item_info = info.item(item_id)
		if item_info and item_info.name then
			return item_info.name
		end
	end
	return name
end

function get_shopping_list_filter_string(items)
	local queries = T.acquire()
	for _, item_name in ipairs(items or T.empty) do
		local normalized_name = normalize_item_name(item_name)
		if normalized_name then
			tinsert(queries, strlower(normalized_name) .. '/exact')
		end
	end
	return aux.join(queries, ';')
end

local function shopping_list_summary(shopping_list)
	local count = getn(shopping_list.items or T.empty)
	return string.format('%s (%d)', shopping_list.name or 'Buy List', count)
end

function update_buy_list_items_listing()
	if not buy_list_items_listing then return end
	local rows = T.acquire()
	for i, item_name in ipairs(buy_list_editor.items or T.empty) do
		tinsert(rows, T.map(
			'cols', T.list(T.map('value', i), T.map('value', item_name)),
			'index', i,
			'item_name', item_name
		))
	end
	buy_list_items_listing:SetData(rows)
end

function update_buy_list_editor()
	if not buy_list_name_input or not buy_list_item_input then return end
	buy_list_name_input:SetText(buy_list_editor.name or '')
	buy_list_name_input.overlay:SetText(buy_list_name_input:GetText())
	buy_list_item_input:SetText('')
	buy_list_item_input.overlay:SetText('')
	update_buy_list_items_listing()
end

function reset_buy_list_editor()
	buy_list_editor.name = ''
	buy_list_editor.items = {}
	buy_list_editor.edit_index = nil
	update_buy_list_editor()
end

function select_buy_list(index)
	selected_buy_list_index = index
	if favorite_searches_listing and favorite_searches_listing.Update then
		favorite_searches_listing:Update()
	end
end

function load_buy_list_editor(index)
	select_buy_list(index)
	local shopping_list = shopping_lists and shopping_lists[index]
	if not shopping_list then return end
	buy_list_editor.name = shopping_list.name or ''
	buy_list_editor.items = aux.copy(shopping_list.items or T.empty)
	buy_list_editor.edit_index = index
	update_buy_list_editor()
end

function load_selected_buy_list()
	if not selected_buy_list_index or not (shopping_lists and shopping_lists[selected_buy_list_index]) then
		aux.print('Select a buy list first.')
		return
	end
	load_buy_list_editor(selected_buy_list_index)
end

function add_buy_list_item(name)
	name = normalize_item_name(name or (buy_list_item_input and buy_list_item_input:GetText()))
	if not name then
		aux.print('Enter an item name to add to the buy list.')
		return
	end
	for _, existing_name in ipairs(buy_list_editor.items) do
		if strlower(existing_name) == strlower(name) then
			if buy_list_item_input then
				buy_list_item_input:SetText('')
				buy_list_item_input.overlay:SetText('')
			end
			return
		end
	end
	tinsert(buy_list_editor.items, name)
	if buy_list_item_input then
		buy_list_item_input:SetText('')
		buy_list_item_input.overlay:SetText('')
		buy_list_item_input:SetFocus()
	end
	update_buy_list_items_listing()
end

function remove_buy_list_item(index)
	if buy_list_editor.items[index] then
		tremove(buy_list_editor.items, index)
		update_buy_list_items_listing()
	end
end

function delete_buy_list(index)
	if not (shopping_lists and shopping_lists[index]) then return end
	tremove(shopping_lists, index)
	if buy_list_editor.edit_index then
		if buy_list_editor.edit_index == index then
			reset_buy_list_editor()
		elseif buy_list_editor.edit_index > index then
			buy_list_editor.edit_index = buy_list_editor.edit_index - 1
		end
	end
	if selected_buy_list_index then
		if selected_buy_list_index == index then
			selected_buy_list_index = nil
		elseif selected_buy_list_index > index then
			selected_buy_list_index = selected_buy_list_index - 1
		end
	end
	update_search_listings()
end

function delete_selected_buy_list()
	if not selected_buy_list_index or not (shopping_lists and shopping_lists[selected_buy_list_index]) then
		aux.print('Select a buy list first.')
		return
	end
	delete_buy_list(selected_buy_list_index)
end

function save_buy_list()
	local name = aux.trim(buy_list_name_input and buy_list_name_input:GetText() or buy_list_editor.name or '')
	if name == '' then
		aux.print('Give the buy list a name first.')
		return
	elseif getn(buy_list_editor.items) == 0 then
		aux.print('Add at least one item to the buy list first.')
		return
	end

	local shopping_list = T.map(
		'name', name,
		'items', aux.copy(buy_list_editor.items),
		'filter_string', get_shopping_list_filter_string(buy_list_editor.items)
	)

	if buy_list_editor.edit_index and shopping_lists[buy_list_editor.edit_index] then
		shopping_lists[buy_list_editor.edit_index] = shopping_list
		select_buy_list(buy_list_editor.edit_index)
	else
		tinsert(shopping_lists, 1, shopping_list)
		select_buy_list(1)
	end

	update_search_listings()
	reset_buy_list_editor()
end

function execute_shopping_list(shopping_list, append_only)
	if not shopping_list then return end
	local filter_string = shopping_list.filter_string
	if not filter_string or filter_string == '' then
		filter_string = get_shopping_list_filter_string(shopping_list.items)
		shopping_list.filter_string = filter_string
	end
	if append_only then
		add_filter(filter_string)
	else
		set_filter(filter_string)
		execute()
	end
end

function update_search_listings()
	local favorite_search_rows = T.acquire()
	for i = 1, getn(shopping_lists or T.empty) do
		local shopping_list = shopping_lists[i]
		tinsert(favorite_search_rows, T.map(
			'cols', T.list(T.map('value', selected_buy_list_index == i and aux.color.gold('L') or aux.color.green('L')), T.map('value', shopping_list_summary(shopping_list))),
			'kind', 'shopping_list',
			'list', shopping_list,
			'index', i
		))
	end
	for i = 1, getn(favorite_searches or T.empty) do
		local search = favorite_searches[i]
		local name = strsub(search.prettified, 1, 250)
		tinsert(favorite_search_rows, T.map(
			'cols', T.list(T.map('value', search.auto_buy and aux.color.red('X') or search.auto_bid and aux.color.red('Y') or ''), T.map('value', name)),
			'kind', 'favorite',
			'search', search,
			'index', i
		))
	end
	favorite_searches_listing:SetData(favorite_search_rows)

	local recent_search_rows = T.acquire()
	for i = 1, getn(recent_searches or T.empty) do
		local search = recent_searches[i]
		local name = strsub(search.prettified, 1, 250)
		tinsert(recent_search_rows, T.map(
			'cols', T.list(T.map('value', name)),
			'search', search,
			'index', i
		))
	end
	recent_searches_listing:SetData(recent_search_rows)
	update_buy_list_items_listing()
end

function new_recent_search(filter_string, prettified)
	for i = getn(recent_searches), 1, -1 do
		if recent_searches[i].filter_string == filter_string then
			tremove(recent_searches, i)
		end
	end
	tinsert(recent_searches, 1, T.map(
		'filter_string', filter_string,
		'prettified', prettified
	))
	while getn(recent_searches) > 50 do
		tremove(recent_searches)
	end
	update_search_listings()
end

handlers = {
	OnClick = function(st, data, _, button)
		if not data then return end

		if data.kind == 'shopping_list' then
			select_buy_list(data.index)
			if button == 'LeftButton' and IsShiftKeyDown() then
				set_filter(data.list.filter_string or get_shopping_list_filter_string(data.list.items))
			elseif button == 'RightButton' and IsShiftKeyDown() then
				add_filter(data.list.filter_string or get_shopping_list_filter_string(data.list.items))
			elseif button == 'LeftButton' then
				execute_shopping_list(data.list)
			elseif button == 'RightButton' then
				local u = update_search_listings
				gui.menu(
					'Edit', function() load_buy_list_editor(data.index) end,
					'Move Up', function() move_up(shopping_lists, data.index); u() end,
					'Move Down', function() move_down(shopping_lists, data.index); u() end,
					'Delete', function() delete_buy_list(data.index) end
				)
			end
			return
		end

		if button == 'LeftButton' and IsShiftKeyDown() then
			set_filter(data.search.filter_string)
		elseif button == 'RightButton' and IsShiftKeyDown() then
			add_filter(data.search.filter_string)
		elseif button == 'LeftButton' then
			set_filter(data.search.filter_string)
			execute()
		elseif button == 'RightButton' then
			local u = update_search_listings
			if st == recent_searches_listing then
				tinsert(favorite_searches, 1, data.search)
				u()
			elseif st == favorite_searches_listing then
				local auto_buy = data.search.auto_buy
				local auto_bid = data.search.auto_bid
				gui.menu(
					(auto_buy and 'Disable' or 'Enable') .. ' Auto Buy', function() if auto_buy then data.search.auto_buy = nil else enable_auto_buy(data.search) end; u() end,
					(auto_bid and 'Disable' or 'Enable') .. ' Auto Bid', function() if auto_bid then data.search.auto_bid = nil else enable_auto_bid(data.search) end; u() end,
					'Move Up', function() move_up(favorite_searches, data.index); u() end,
					'Move Down', function() move_down(favorite_searches, data.index); u() end,
					'Delete', function() tremove(favorite_searches, data.index); u() end
				)
			end
		end
	end,
	OnEnter = function(st, data, self)
		if not data then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		if data.kind == 'shopping_list' then
			GameTooltip:AddLine(data.list.name or 'Buy List', 255/255, 254/255, 250/255)
			GameTooltip:AddLine(' ')
			for _, item_name in ipairs(data.list.items or T.empty) do
				GameTooltip:AddLine(item_name, 255/255, 254/255, 250/255, true)
			end
		else
			GameTooltip:AddLine(gsub(data.search.prettified, ';', string.char(10) .. string.char(10)), 255/255, 254/255, 250/255, true)
		end
		GameTooltip:Show()
	end,
	OnLeave = function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
}

buy_list_item_handlers = {
	OnClick = function(_, data, _, button)
		if not data then return end
		if button == 'RightButton' then
			gui.menu('Remove', function() remove_buy_list_item(data.index) end)
		else
			buy_list_item_input:SetText(data.item_name or '')
			buy_list_item_input.overlay:SetText(data.item_name or '')
			buy_list_item_input:SetFocus()
		end
	end,
	OnEnter = function(_, data)
		if not data then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:AddLine(data.item_name or '', 255/255, 254/255, 250/255, true)
		GameTooltip:AddLine('Right-click to remove', .8, .8, .8)
		GameTooltip:Show()
	end,
	OnLeave = function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
}

function get_auto_buy_validator()
	if not favorite_searches then return end
	
	local validators = T.acquire()
	for _, search in favorite_searches do
		if search.auto_buy then
			local queries, error = filter_util.queries(search.filter_string)
			if queries then
				tinsert(validators, queries[1].validator)
			else
				aux.print('Invalid auto buy filter:', error)
			end
		end
	end
	return function(record)
		return aux.any(validators, function(validator) return validator(record) end)
	end
end

function get_auto_bid_validator()
	if not favorite_searches then return end
	
	local validators = T.acquire()
	for _, search in favorite_searches do
		if search.auto_bid then
			local queries, error = filter_util.queries(search.filter_string)
			if queries then
				tinsert(validators, queries[1].validator)
			else
				aux.print('Invalid auto bid filter:', error)
			end
		end
	end
	return function(record)
		return aux.any(validators, function(validator) return validator(record) end)
	end
end

function add_favorite(filter_string)
	local queries, error = filter_util.queries(filter_string)
	if queries then
		tinsert(favorite_searches, 1, T.map(
			'filter_string', filter_string,
			'prettified', aux.join(aux.map(queries, function(query) return query.prettified end), ';')
		))
		update_search_listings()
	else
		aux.print('Invalid filter:', error)
	end
end

function enable_auto_buy(search)
	local queries, error = filter_util.queries(search.filter_string)
	if queries then
		if getn(queries) > 1 then
			aux.print('Error: Auto Buy does not support multi-queries')
		else
			if aux.size(queries[1].blizzard_query) > 0 and not filter_util.parse_filter_string(search.filter_string).blizzard.exact then
				aux.print(aux.color.orange('Warning: Auto Buy with Blizzard filters will only work when scanning that category'))
			end
			search.auto_buy = true
		end
	else
		aux.print('Invalid filter:', error)
	end
end

function enable_auto_bid(search)
	local queries, error = filter_util.queries(search.filter_string)
	if queries then
		if getn(queries) > 1 then
			aux.print('Error: Auto Bid does not support multi-queries')
		else
			if aux.size(queries[1].blizzard_query) > 0 and not filter_util.parse_filter_string(search.filter_string).blizzard.exact then
				aux.print(aux.color.orange('Warning: Auto Bid with Blizzard filters will only work when scanning that category'))
			end
			search.auto_bid = true
		end
	else
		aux.print('Invalid filter:', error)
	end
end

function move_up(list, index)
	if list[index - 1] then
		list[index], list[index - 1] = list[index - 1], list[index]
	end
end

function move_down(list, index)
	if list[index + 1] then
		list[index], list[index + 1] = list[index + 1], list[index]
	end
end
