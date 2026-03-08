import QtQuick

ListModel {
	id: resultModel

	signal refreshing()
	signal refreshed()

	function refresh() {
		refreshing()
		
		//--- populate list
		var resultList = [];
		for (var i = 0; i < runnerModel.count; i++){
			var runner = runnerModel.modelForRow(i);
			for (var j = 0; j < runner.count; j++) {
				// RunnerMatchesModel.modelForRow is NOT implemented.
				// We need to use model.data(model.index(row, 0), role)
				// https://github.com/KDE/plasma-workspace/blame/master/applets/kicker/plugin/abstractmodel.cpp#L35
				// https://github.com/KDE/plasma-workspace/blame/master/applets/kicker/plugin/runnermatchesmodel.cpp#L54

				// https://github.com/KDE/plasma-workspace/blame/master/applets/kicker/plugin/actionlist.h#L30
				var DescriptionRole = Qt.UserRole + 1;
				var GroupRole = DescriptionRole + 1;
				var FavoriteIdRole = DescriptionRole + 2;
				var IsSeparatorRole = DescriptionRole + 3;
				var IsDropPlaceholderRole = DescriptionRole + 4;
				var IsParentRole = DescriptionRole + 5;
				var HasChildrenRole = DescriptionRole + 6;
				var HasActionListRole = DescriptionRole + 7;
				var ActionListRole = DescriptionRole + 8;
				var UrlRole = DescriptionRole + 9;

				var modelIndex = runner.index(j, 0);

				// When RunnerModel.mergeResults is enabled, GroupRole is typically the
				// originating runner/category name (e.g. Applications, System Settings).
				// Use it for grouping in the UI.
				var group = runner.data(modelIndex, GroupRole);
				if (typeof group === 'object') {
					group = group.toString();
				} else if (typeof group === 'undefined') {
					group = '';
				}
				var sectionName = runnerModel.mergeResults ? (group || runner.name) : runner.name;

				// ListView.append() doesn't like it when we have { key: [object] }.
				var url = runner.data(modelIndex, UrlRole);
				if (typeof url === 'object') {
					url = url.toString();
				} else if (typeof url === 'undefined') {
					url = ''
				}
				var icon = runner.data(modelIndex, Qt.DecorationRole);
				if (typeof icon === 'object') {
					icon = icon.toString();
				}

				var favoriteId = runner.data(modelIndex, FavoriteIdRole)
				if (typeof favoriteId === 'undefined') {
					favoriteId = ''
				}

				var name = runner.data(modelIndex, Qt.DisplayRole)
				var description = runner.data(modelIndex, DescriptionRole)

				var resultItem = {
					runnerIndex: i,
					runnerId: (typeof runner.runnerId !== 'undefined' && runner.runnerId) ? ('' + runner.runnerId) : '',
					runnerName: runner.name,
					group: group,
					sectionName: sectionName,
					runnerItemIndex: j,
					name: name,
					description: description,
					icon: icon,
					url: url,
					favoriteId: favoriteId,
					largeIcon: false, // for KickerListView
				};
				resultList.push(resultItem);
			}
		}

		//--- Ensure grouped headers are contiguous when runner results are merged.
		// Preserve the original order within each section.
		if (plasmoid.configuration.searchResultsGrouped && runnerModel.mergeResults) {
			var sectionOrder = []
			var sectionBuckets = {}
			for (var gi = 0; gi < resultList.length; gi++) {
				var item = resultList[gi]
				var key = item && item.sectionName ? item.sectionName : ''
				if (!sectionBuckets[key]) {
					sectionBuckets[key] = []
					sectionOrder.push(key)
				}
				sectionBuckets[key].push(item)
			}
			var regrouped = []
			for (var so = 0; so < sectionOrder.length; so++) {
				var sec = sectionOrder[so]
				var bucket = sectionBuckets[sec]
				for (var bi = 0; bi < bucket.length; bi++) {
					regrouped.push(bucket[bi])
				}
			}
			resultList = regrouped
		}

		//--- Make the (selected) first item bigger.
		if (resultList.length > 0) {
			resultList[0].largeIcon = true
		}

		//--- apply model
		resultModel.clear();
		for (var i = 0; i < resultList.length; i++) {
			resultModel.append(resultList[i]);
		}

		//--- listen for changes
		for (var i = 0; i < runnerModel.count; i++){
			var runner = runnerModel.modelForRow(i);
			if (!runner.listenersBound) {
				runner.countChanged.connect(debouncedRefresh.logAndRestart)
				runner.dataChanged.connect(debouncedRefresh.logAndRestart)
				runner.listenersBound = true;
			}
		}

		refreshed()
	}

	function triggerIndex(index) {
		var ctx = getRunnerContext(index)
		if (!ctx) {
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.triggerIndex: missing runner context', index)
			}
			console.warn('SearchResultsModel.triggerIndex missing ctx', index)
			return
		}
		var closeRequested = false
		try {
			closeRequested = ctx.runner.trigger(ctx.itemIndex, "", null)
		} catch (e) {
			console.warn('SearchResultsModel.triggerIndex exception', index, e)
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.triggerIndex exception', index, e)
			}
		}
		if (closeRequested) {
			plasmoid.expanded = false
		}
		itemTriggered()
	}
	
	signal itemTriggered()

	function hasActionList(index) {
		var DescriptionRole = Qt.UserRole + 1;
		var HasActionListRole = DescriptionRole + 7;

		var ctx = getRunnerContext(index)
		if (!ctx) {
			return false
		}
		return ctx.runner.data(ctx.modelIndex, HasActionListRole)
	}

	function getActionList(index) {
		var DescriptionRole = Qt.UserRole + 1;
		var ActionListRole = DescriptionRole + 8;

		var ctx = getRunnerContext(index)
		if (!ctx) {
			return []
		}
		return ctx.runner.data(ctx.modelIndex, ActionListRole)
	}

	function triggerIndexAction(index, actionId, actionArgument) {
		// kicker/code/tools.js triggerAction()
		var ctx = getRunnerContext(index)
		if (!ctx) {
			console.warn('SearchResultsModel.triggerIndexAction missing ctx', index, actionId)
			return
		}
		var closeRequested = false
		try {
			closeRequested = ctx.runner.trigger(ctx.itemIndex, actionId, actionArgument)
		} catch (e) {
			console.warn('SearchResultsModel.triggerIndexAction exception', index, actionId, e)
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.triggerIndexAction exception', index, actionId, e)
			}
		}
		if (closeRequested) {
			plasmoid.expanded = false
		}
		itemTriggered()

		// Note that Recent Documents actions do not work (in the search results) as of Plasma 5.8.4
		// https://bugs.kde.org/show_bug.cgi?id=373173
	}

	function getRunnerContext(index) {
		var model = resultModel.get(index)
		if (!model) {
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.getRunnerContext: missing model', index)
			}
			console.warn('SearchResultsModel.getRunnerContext missing model', index)
			return null
		}
		var runner = runnerModel.modelForRow(model.runnerIndex)
		if (!runner || typeof runner.count === 'undefined') {
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.getRunnerContext: missing runner', index, model.runnerIndex)
			}
			console.warn('SearchResultsModel.getRunnerContext missing runner', index, model.runnerIndex)
			return null
		}
		if (model.runnerItemIndex < 0 || model.runnerItemIndex >= runner.count) {
			if (typeof logger !== "undefined" && logger) {
				logger.warn('SearchResultsModel.getRunnerContext: invalid runnerItemIndex', index, model.runnerItemIndex, 'count', runner.count)
			}
			console.warn('SearchResultsModel.getRunnerContext invalid runnerItemIndex', index, model.runnerItemIndex, runner.count)
			return null
		}
		return {
			runner: runner,
			modelIndex: runner.index(model.runnerItemIndex, 0),
			itemIndex: model.runnerItemIndex
		}
	}
}
