{include file='include/tag_selection.inc.tpl'}
{include file='include/datepicker.inc.tpl'}
{include file='include/colorbox.inc.tpl'}
{include file='include/add_album.inc.tpl'}

{footer_script}{literal}
  pwg_initialization_datepicker("#date_creation_day", "#date_creation_month", "#date_creation_year", "#date_creation_linked_date", "#date_creation_action_set");
{/literal}{/footer_script}

{footer_script}{literal}
/* Shift-click: select all photos between the click and the shift+click */
jQuery(document).ready(function() {
  var last_clicked=0;
  var last_clickedstatus=true;
  jQuery.fn.enableShiftClick = function() {
    var inputs = [];
    var count=0;
    var This=$(this);
    this.find('input[type=checkbox]').each(function() {
      var pos=count;
      inputs[count++]=this;
      $(this).bind("shclick", function (dummy,event) {
        if (event.shiftKey) {
          var first = last_clicked;
          var last = pos;
          if (first > last) {
            first=pos;
            last=last_clicked;
          }

          for (var i=first; i<=last;i++) {
            input = $(inputs[i]);
            $(input).attr('checked', last_clickedstatus);
            if (last_clickedstatus)
            {
              $(input).siblings("span.wrap2").addClass("thumbSelected");
            }
            else
            {
              $(input).siblings("span.wrap2").removeClass("thumbSelected");
            }
          }
        }
        else {
          last_clicked = pos;
          last_clickedstatus = this.checked;
        }
        return true;
      });
      $(this).click(function(event) {console.log(event.shiftKey);$(this).triggerHandler("shclick",event)});
    });
  }
	$('ul.thumbnails').enableShiftClick();
});
{/literal}{/footer_script}

{combine_script id='jquery.tokeninput' load='footer' require='jquery' path='themes/default/js/plugins/jquery.tokeninput.js'}
{combine_script id='jquery.progressBar' load='footer' path='themes/default/js/plugins/jquery.progressbar.min.js'}
{combine_script id='jquery.ajaxmanager' load='footer' path='themes/default/js/plugins/jquery.ajaxmanager.js'}

{footer_script require='jquery.tokeninput'}
jQuery(document).ready(function() {ldelim}
  jQuery("a.preview-box").colorbox();
  
	var tag_src = [{foreach from=$tags item=tag name=tags}{ldelim}name:"{$tag.name|@escape:'javascript'}",id:"{$tag.id}"{rdelim}{if !$smarty.foreach.tags.last},{/if}{/foreach}];
  jQuery("#tags").tokenInput(
    tag_src,
    {ldelim}
      hintText: '{'Type in a search term'|@translate}',
      noResultsText: '{'No results'|@translate}',
      searchingText: '{'Searching...'|@translate}',
      newText: ' ({'new'|@translate})',
      animateDropdown: false,
      preventDuplicates: true,
      allowCreation: true
    }
  );
	
  jQuery("#tagsFilter").tokenInput(
    tag_src,
    {ldelim}
      hintText: '{'Type in a search term'|@translate}',
      noResultsText: '{'No results'|@translate}',
      searchingText: '{'Searching...'|@translate}',
      animateDropdown: false,
      preventDuplicates: true,
      allowCreation: false
    }
  );

});
{/footer_script}

{footer_script}
var nb_thumbs_page = {$nb_thumbs_page};
var nb_thumbs_set = {$nb_thumbs_set};
var applyOnDetails_pattern = "{'on the %d selected photos'|@translate}";
var all_elements = [{if !empty($all_elements)}{','|@implode:$all_elements}{/if}];
var derivatives = {ldelim}
	elements: null,
	done: 0,
	total: 0,
	
	finished: function() {ldelim}
		return derivatives.done == derivatives.total && derivatives.elements && derivatives.elements.length==0;
	}
};

var selectedMessage_pattern = "{'%d of %d photos selected'|@translate}";
var selectedMessage_none = "{'No photo selected, %d photos in current set'|@translate}";
var selectedMessage_all = "{'All %d photos are selected'|@translate}";

var width_str = '{'Width'|@translate}';
var height_str = '{'Height'|@translate}';
var max_width_str = '{'Maximum width'|@translate}';
var max_height_str = '{'Maximum height'|@translate}';
{literal}
function str_repeat(i, m) {
        for (var o = []; m > 0; o[--m] = i);
        return o.join('');
}

function sprintf() {
        var i = 0, a, f = arguments[i++], o = [], m, p, c, x, s = '';
        while (f) {
                if (m = /^[^\x25]+/.exec(f)) {
                        o.push(m[0]);
                }
                else if (m = /^\x25{2}/.exec(f)) {
                        o.push('%');
                }
                else if (m = /^\x25(?:(\d+)\$)?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(f)) {
                        if (((a = arguments[m[1] || i++]) == null) || (a == undefined)) {
                                throw('Too few arguments.');
                        }
                        if (/[^s]/.test(m[7]) && (typeof(a) != 'number')) {
                                throw('Expecting number but found ' + typeof(a));
                        }
                        switch (m[7]) {
                                case 'b': a = a.toString(2); break;
                                case 'c': a = String.fromCharCode(a); break;
                                case 'd': a = parseInt(a); break;
                                case 'e': a = m[6] ? a.toExponential(m[6]) : a.toExponential(); break;
                                case 'f': a = m[6] ? parseFloat(a).toFixed(m[6]) : parseFloat(a); break;
                                case 'o': a = a.toString(8); break;
                                case 's': a = ((a = String(a)) && m[6] ? a.substring(0, m[6]) : a); break;
                                case 'u': a = Math.abs(a); break;
                                case 'x': a = a.toString(16); break;
                                case 'X': a = a.toString(16).toUpperCase(); break;
                        }
                        a = (/[def]/.test(m[7]) && m[2] && a >= 0 ? '+'+ a : a);
                        c = m[3] ? m[3] == '0' ? '0' : m[3].charAt(1) : ' ';
                        x = m[5] - String(a).length - s.length;
                        p = m[5] ? str_repeat(c, x) : '';
                        o.push(s + (m[4] ? a + p : p + a));
                }
                else {
                        throw('Huh ?!');
                }
                f = f.substring(m[0].length);
        }
        return o.join('');
}

function progress(success) {
  jQuery('#progressBar').progressBar(derivatives.done, {
    max: derivatives.total,
    textFormat: 'fraction',
    boxImage: 'themes/default/images/progressbar.gif',
    barImage: 'themes/default/images/progressbg_orange.gif'
  });
	if (success !== undefined) {
		var type = success ? 'regenerateSuccess': 'regenerateError',
			s = jQuery('[name="'+type+'"]').val();
		jQuery('[name="'+type+'"]').val(++s);
	}

	if (derivatives.finished()) {
		jQuery('#applyAction').click();
	}
}

$(document).ready(function() {
  function checkPermitAction() {
    var nbSelected = 0;
    if ($("input[name=setSelected]").is(':checked')) {
      nbSelected = nb_thumbs_set;
    }
    else {
      $(".thumbnails input[type=checkbox]").each(function() {
         if ($(this).is(':checked')) {
           nbSelected++;
         }
      });
    }

    if (nbSelected == 0) {
      $("#permitAction").hide();
      $("#forbidAction").show();
    }
    else {
      $("#permitAction").show();
      $("#forbidAction").hide();
    }

    $("#applyOnDetails").text(
      sprintf(
        applyOnDetails_pattern,
        nbSelected
      )
    );

    // display the number of currently selected photos in the "Selection" fieldset
    if (nbSelected == 0) {
      $("#selectedMessage").text(
        sprintf(
          selectedMessage_none,
          nb_thumbs_set
        )
      );
    }
    else if (nbSelected == nb_thumbs_set) {
      $("#selectedMessage").text(
        sprintf(
          selectedMessage_all,
          nb_thumbs_set
        )
      );
    }
    else {
      $("#selectedMessage").text(
        sprintf(
          selectedMessage_pattern,
          nbSelected,
          nb_thumbs_set
        )
      );
    }
  }

  $('.thumbnails img').tipTip({
    'delay' : 0,
    'fadeIn' : 200,
    'fadeOut' : 200
  });

  $("[id^=action_]").hide();

  $("select[name=selectAction]").change(function () {
    $("[id^=action_]").hide();
    $("#action_"+$(this).attr("value")).show();

    /* make sure the #albumSelect is on the right select box so that the */
    /* "add new album" popup fills the right select box                  */
    if ("associate" == $(this).attr("value") || "move" == $(this).attr("value")) {
      jQuery("#albumSelect").removeAttr("id");
      jQuery("#action_"+$(this).attr("value")+" select").attr("id", "albumSelect");
    }

    if ($(this).val() != -1) {
      $("#applyActionBlock").show();
    }
    else {
      $("#applyActionBlock").hide();
    }
  });

  $(".wrap1 label").click(function (event) {
    $("input[name=setSelected]").attr('checked', false);

    var wrap2 = $(this).children(".wrap2");
    var checkbox = $(this).children("input[type=checkbox]");

    checkbox.triggerHandler("shclick",event);

    if ($(checkbox).is(':checked')) {
      $(wrap2).addClass("thumbSelected"); 
    }
    else {
      $(wrap2).removeClass('thumbSelected'); 
    }

    checkPermitAction();
  });

  $("#selectAll").click(function () {
    $("input[name=setSelected]").attr('checked', false);
    selectPageThumbnails();
    checkPermitAction();
    return false;
  });

  function selectPageThumbnails() {
    $(".thumbnails label").each(function() {
      var wrap2 = $(this).children(".wrap2");
      var checkbox = $(this).children("input[type=checkbox]");

      $(checkbox).attr('checked', true);
      $(wrap2).addClass("thumbSelected"); 
    });
  }

  $("#selectNone").click(function () {
    $("input[name=setSelected]").attr('checked', false);

    $(".thumbnails label").each(function() {
      var wrap2 = $(this).children(".wrap2");
      var checkbox = $(this).children("input[type=checkbox]");

      $(checkbox).attr('checked', false);
      $(wrap2).removeClass("thumbSelected"); 
    });
    checkPermitAction();
    return false;
  });

  $("#selectInvert").click(function () {
    $("input[name=setSelected]").attr('checked', false);

    $(".thumbnails label").each(function() {
      var wrap2 = $(this).children(".wrap2");
      var checkbox = $(this).children("input[type=checkbox]");

      $(checkbox).attr('checked', !$(checkbox).is(':checked'));

      if ($(checkbox).is(':checked')) {
        $(wrap2).addClass("thumbSelected"); 
      }
      else {
        $(wrap2).removeClass('thumbSelected'); 
      }
    });
    checkPermitAction();
    return false;
  });

  $("#selectSet").click(function () {
    selectPageThumbnails();
    $("input[name=setSelected]").attr('checked', true);
    checkPermitAction();
    return false;
  });

  $("input[name=remove_author]").click(function () {
    if ($(this).is(':checked')) {
      $("input[name=author]").hide();
    }
    else {
      $("input[name=author]").show();
    }
  });

  $("input[name=remove_title]").click(function () {
    if ($(this).is(':checked')) {
      $("input[name=title]").hide();
    }
    else {
      $("input[name=title]").show();
    }
  });

  $("input[name=remove_date_creation]").click(function () {
    if ($(this).is(':checked')) {
      $("#set_date_creation").hide();
    }
    else {
      $("#set_date_creation").show();
    }
  });

  $(".removeFilter").click(function () {
    var filter = $(this).parent('li').attr("id");
    filter_disable(filter);

    return false;
  });

  function filter_enable(filter) {
    /* show the filter*/
    $("#"+filter).show();

    /* check the checkbox to declare we use this filter */
    $("input[type=checkbox][name="+filter+"_use]").attr("checked", true);

    /* forbid to select this filter in the addFilter list */
    $("#addFilter").children("option[value="+filter+"]").attr("disabled", "disabled");
  }

  $("#addFilter").change(function () {
    var filter = $(this).attr("value");
    filter_enable(filter);
    $(this).attr("value", -1);
  });
  
  $("select[name='filter_dimension']").change(function () {
    $("span[id^='filter_dimension_']").hide();
    $("span#filter_dimension_"+ $(this).attr("value")).show();
  });

  function filter_disable(filter) {
    /* hide the filter line */
    $("#"+filter).hide();

    /* uncheck the checkbox to declare we do not use this filter */
    $("input[name="+filter+"_use]").removeAttr("checked");

    /* give the possibility to show it again */
    $("#addFilter").children("option[value="+filter+"]").removeAttr("disabled");
  }

  $("#removeFilters").click(function() {
    $("#filterList li").each(function() {
      var filter = $(this).attr("id");
      filter_disable(filter);
    });
    return false;
  });

  jQuery('#applyAction').click(function() {
		if (jQuery('[name="selectAction"]').val() != 'generate_derivatives'
			|| derivatives.finished() )
		{
			return true;
		}

		jQuery('.bulkAction').hide();

		var queuedManager = jQuery.manageAjax.create('queued', { 
			queue: true,  
			cacheResponse: false,
			maxRequests: 1
		});

		derivatives.elements = [];
		if (jQuery('input[name="setSelected"]').attr('checked'))
			derivatives.elements = all_elements;
		else
			jQuery('input[name="selection[]"]').each(function() {
				if (jQuery(this).attr('checked')) {
					derivatives.elements.push(jQuery(this).val());
				}
			});

		jQuery('#applyActionBlock').hide();
		jQuery('select[name="selectAction"]').hide();
		jQuery('#regenerationMsg').show();
		
		progress();
		getDerivativeUrls();
		return false;
  });

	function getDerivativeUrls() {
		var ids = derivatives.elements.splice(0, 500);
		var params = {max_urls: 100000, ids: ids, types: []};
		jQuery("#action_generate_derivatives input").each( function(i, t) {
			if ($(t).attr("checked"))
				params.types.push( t.value );
		} );

		jQuery.ajax( {
			type: "POST",
			url: 'ws.php?format=json&method=pwg.getMissingDerivatives',
			data: params,
			dataType: "json",
			success: function(data) {
				if (!data.stat || data.stat != "ok") {
					return;
				}
				derivatives.total += data.result.urls.length;
				progress();
				for (var i=0; i < data.result.urls.length; i++) {
					jQuery.manageAjax.add("queued", {
						type: 'GET', 
						url: data.result.urls[i] + "&ajaxload=true", 
						dataType: 'json',
						success: ( function(data) { derivatives.done++; progress(true) }),
						error: ( function(data) { derivatives.done++; progress(false) })
					});
				}
				if (derivatives.elements.length)
					setTimeout( getDerivativeUrls, 25 * (derivatives.total-derivatives.done));
			}
		} );
	}

  checkPermitAction()
});


{/literal}{/footer_script}

<div id="batchManagerGlobal">

<h2>{'Batch Manager'|@translate}</h2>

  <form action="{$F_ACTION}" method="post">
	<input type="hidden" name="start" value="{$START}">

  <fieldset>
    <legend>{'Filter'|@translate}</legend>

    <ul id="filterList">
      <li id="filter_prefilter" {if !isset($filter.prefilter)}style="display:none"{/if}>
        <a href="#" class="removeFilter" title="{'remove this filter'|@translate}"><span>[x]</span></a>
        <input type="checkbox" name="filter_prefilter_use" class="useFilterCheckbox" {if isset($filter.prefilter)}checked="checked"{/if}>
        {'Predefined filter'|@translate}
        <select name="filter_prefilter">
          {foreach from=$prefilters item=prefilter}
          <option value="{$prefilter.ID}" {if isset($filter.prefilter) && $filter.prefilter eq $prefilter.ID}selected="selected"{/if}>{$prefilter.NAME}</option>
          {/foreach}
        </select>
      </li>
      
      <li id="filter_category" {if !isset($filter.category)}style="display:none"{/if}>
        <a href="#" class="removeFilter" title="remove this filter"><span>[x]</span></a>
        <input type="checkbox" name="filter_category_use" class="useFilterCheckbox" {if isset($filter.category)}checked="checked"{/if}>
        {'Album'|@translate}
        <select style="width:400px" name="filter_category" size="1">
          {html_options options=$filter_category_options selected=$filter_category_options_selected}
        </select>
        <label><input type="checkbox" name="filter_category_recursive" {if isset($filter.category_recursive)}checked="checked"{/if}> {'include child albums'|@translate}</label>
      </li>
      
      <li id="filter_tags" {if !isset($filter.tags)}style="display:none"{/if}>
        <a href="#" class="removeFilter" title="remove this filter"><span>[x]</span></a>
        <input type="checkbox" name="filter_tags_use" class="useFilterCheckbox" {if isset($filter.tags)}checked="checked"{/if}>
        {'Tags'|@translate}
        <select id="tagsFilter" name="filter_tags">
          {if isset($filter_tags)}{foreach from=$filter_tags item=tag}
          <option value="{$tag.id}">{$tag.name}</option>
          {/foreach}{/if}
        </select>
        <label><span><input type="radio" name="tag_mode" value="AND" {if !isset($filter.tag_mode) or $filter.tag_mode eq 'AND'}checked="checked"{/if}> {'All tags'|@translate}</span></label>
        <label><span><input type="radio" name="tag_mode" value="OR" {if isset($filter.tag_mode) and $filter.tag_mode eq 'OR'}checked="checked"{/if}> {'Any tag'|@translate}</span></label>
      </li>
      
      <li id="filter_level" {if !isset($filter.level)}style="display:none"{/if}>
        <a href="#" class="removeFilter" title="remove this filter"><span>[x]</span></a>
        <input type="checkbox" name="filter_level_use" class="useFilterCheckbox" {if isset($filter.level)}checked="checked"{/if}>
        {'Privacy level'|@translate}
        <select name="filter_level" size="1">
          {html_options options=$filter_level_options selected=$filter_level_options_selected}
        </select>
        <label><input type="checkbox" name="filter_level_include_lower" {if isset($filter.level_include_lower)}checked="checked"{/if}> {'include photos with lower privacy level'|@translate}</label>
      </li>
      
      <li id="filter_dimension" {if !isset($filter.dimension)}style="display:none"{/if}>
        <a href="#" class="removeFilter" title="remove this filter"><span>[x]</span></a>
        <input type="checkbox" name="filter_dimension_use" class="useFilterCheckbox" {if isset($filter.dimension)}checked="checked"{/if}>
        <select name="filter_dimension">
          <option value="min_width" {if $filter.dimension=='min_width'}selected="selected"{/if}>{'Minimum width'|@translate}</option>
          <option value="max_width" {if $filter.dimension=='max_width'}selected="selected"{/if}>{'Maximum width'|@translate}</option>
          <option value="min_height" {if $filter.dimension=='min_height'}selected="selected"{/if}>{'Minimum height'|@translate}</option>
          <option value="max_height" {if $filter.dimension=='max_height'}selected="selected"{/if}>{'Maximum height'|@translate}</option>
          <option value="format" {if $filter.dimension=='format'}selected="selected"{/if}>{'Format'|@translate}</option>
        </select>
        <span id="filter_dimension_min_width" {if !isset($filter.dimension_min_width) and isset($filter.dimension)}style="display:none;"{/if}><input type="text" name="filter_dimension_min_width" value="{$filter.dimension_min_width}" size="4"> px</span>
        <span id="filter_dimension_max_width" {if !isset($filter.dimension_max_width)}style="display:none;"{/if}><input type="text" name="filter_dimension_max_width" value="{$filter.dimension_max_width}" size="4"> px</span>
        <span id="filter_dimension_min_height" {if !isset($filter.dimension_min_height)}style="display:none;"{/if}><input type="text" name="filter_dimension_min_height" value="{$filter.dimension_min_height}" size="4"> px</span>
        <span id="filter_dimension_max_height" {if !isset($filter.dimension_max_height)}style="display:none;"{/if}><input type="text" name="filter_dimension_max_height" value="{$filter.dimension_max_height}" size="4"> px</span>
        <span id="filter_dimension_format" {if !isset($filter.dimension_format)}style="display:none;"{/if}>
          <select name="filter_dimension_format">
            <option value="portrait" {if $filter.dimension_format=='portrait'}selected="selected"{/if}>{'Portrait'|@translate}</option>
            <option value="square" {if $filter.dimension_format=='square'}selected="selected"{/if}>{'square'|@translate}</option>
            <option value="landscape" {if $filter.dimension_format=='landscape'}selected="selected"{/if}>{'Landscape'|@translate}</option>
            <option value="panorama" {if $filter.dimension_format=='panorama'}selected="selected"{/if}>{'Panorama'|@translate}</option>
          </select>
        </span>
      </li>
    </ul>

    <p class="actionButtons">
      <select id="addFilter">
        <option value="-1">{'Add a filter'|@translate}</option>
        <option disabled="disabled">------------------</option>
        <option value="filter_prefilter" {if isset($filter.prefilter)}disabled="disabled"{/if}>{'Predefined filter'|@translate}</option>
        <option value="filter_category" {if isset($filter.category)}disabled="disabled"{/if}>{'Album'|@translate}</option>
        <option value="filter_tags" {if isset($filter.tags)}disabled="disabled"{/if}>{'Tags'|@translate}</option>
        <option value="filter_level" {if isset($filter.level)}disabled="disabled"{/if}>{'Privacy level'|@translate}</option>
        <option value="filter_dimension" {if isset($filter.dimension)}disabled="disabled"{/if}>{'Dimensions'|@translate}</option>
      </select>
<!--      <input id="removeFilters" class="submit" type="submit" value="Remove all filters" name="removeFilters"> -->
      <a id="removeFilters" href="">{'Remove all filters'|@translate}</a>
    </p>

    <p class="actionButtons" id="applyFilterBlock">
      <input id="applyFilter" class="submit" type="submit" value="{'Refresh photo set'|@translate}" name="submitFilter">
    </p>

  </fieldset>

  <fieldset>

    <legend>{'Selection'|@translate}</legend>

  {if !empty($thumbnails)}
  <p id="checkActions">
    {'Select:'|@translate}
{if $nb_thumbs_set > $nb_thumbs_page}
    <a href="#" id="selectAll">{'The whole page'|@translate}</a>,
    <a href="#" id="selectSet">{'The whole set'|@translate}</a>,
{else}
    <a href="#" id="selectAll">{'All'|@translate}</a>,
{/if}
    <a href="#" id="selectNone">{'None'|@translate}</a>,
    <a href="#" id="selectInvert">{'Invert'|@translate}</a>

    <span id="selectedMessage"></span>

    <input type="checkbox" name="setSelected" style="display:none" {if count($selection) == $nb_thumbs_set}checked="checked"{/if}>
  </p>

	<ul class="thumbnails">
		{html_style}
UL.thumbnails SPAN.wrap2{ldelim}
  width: {$thumb_params->max_width()+2}px;
}
UL.thumbnails SPAN.wrap2 {ldelim}
  height: {$thumb_params->max_height()+25}px;
}
		{/html_style}
		{foreach from=$thumbnails item=thumbnail}
		{assign var='isSelected' value=$thumbnail.id|@in_array:$selection}
		<li>
			<span class="wrap1">
				<label>
					<input type="checkbox" name="selection[]" value="{$thumbnail.id}" {if $isSelected}checked="checked"{/if}>
					<span class="wrap2{if $isSelected} thumbSelected{/if}">
					<div class="actions"><a href="{$thumbnail.FILE_SRC}" class="preview-box">{'Zoom'|@translate}</a> &middot; <a href="{$thumbnail.U_EDIT}" target="_blank">{'Edit'|@translate}</a></div>
						{if $thumbnail.level > 0}
						<em class="levelIndicatorB">{$pwg->l10n($pwg->sprintf('Level %d',$thumbnail.level))}</em>
						<em class="levelIndicatorF" title="{'Who can see these photos?'|@translate} : ">{$pwg->l10n($pwg->sprintf('Level %d',$thumbnail.level))}</em>
						{/if}
						<img src="{$thumbnail.thumb->get_url()}" alt="{$thumbnail.file}" title="{$thumbnail.TITLE|@escape:'html'}" {$thumbnail.thumb->get_size_htm()}>
					</span>
				</label>
			</span>
		</li>
		{/foreach}
	</ul>

  {if !empty($navbar) }
  <div style="clear:both;">

    <div style="float:left">
    {include file='navigation_bar.tpl'|@get_extent:'navbar'}
    </div>

    <div style="float:right;margin-top:10px;">{'display'|@translate}
      <a href="{$U_DISPLAY}&amp;display=20">20</a>
      &middot; <a href="{$U_DISPLAY}&amp;display=50">50</a>
      &middot; <a href="{$U_DISPLAY}&amp;display=100">100</a>
      &middot; <a href="{$U_DISPLAY}&amp;display=all">{'all'|@translate}</a>
      {'photos per page'|@translate}
    </div>
  </div>
  {/if}

  {else}
  <div>{'No photo in the current set.'|@translate}</div>
  {/if}
  </fieldset>

  <fieldset id="action">

    <legend>{'Action'|@translate}</legend>
      <div id="forbidAction"{if count($selection) != 0} style="display:none"{/if}>{'No photo selected, no action possible.'|@translate}</div>
      <div id="permitAction"{if count($selection) == 0} style="display:none"{/if}>

    <select name="selectAction">
      <option value="-1">{'Choose an action'|@translate}</option>
      <option disabled="disabled">------------------</option>
  {if isset($show_delete_form) }
      <option value="delete">{'Delete selected photos'|@translate}</option>
  {/if}
      <option value="associate">{'Associate to album'|@translate}</option>
      <option value="move">{'Move to album'|@translate}</option>
  {if !empty($dissociate_options)}
      <option value="dissociate">{'Dissociate from album'|@translate}</option>
  {/if}
      <option value="add_tags">{'Add tags'|@translate}</option>
  {if !empty($DEL_TAG_SELECTION)}
      <option value="del_tags">{'remove tags'|@translate}</option>
  {/if}
      <option value="author">{'Set author'|@translate}</option>
      <option value="title">{'Set title'|@translate}</option>
      <option value="date_creation">{'Set creation date'|@translate}</option>
      <option value="level">{'Who can see these photos?'|@translate}</option>
      <option value="metadata">{'Synchronize metadata'|@translate}</option>
  {if ($IN_CADDIE)}
      <option value="remove_from_caddie">{'Remove from caddie'|@translate}</option>
  {else}
      <option value="add_to_caddie">{'Add to caddie'|@translate}</option>
  {/if}
		<option value="delete_derivatives">{'Delete multiple size images'|@translate}</option>
		<option value="generate_derivatives">{'Generate multiple size images'|@translate}</option>
  {if !empty($element_set_global_plugins_actions)}
    {foreach from=$element_set_global_plugins_actions item=action}
      <option value="{$action.ID}">{$action.NAME}</option>
    {/foreach}
  {/if}
    </select>

    <!-- delete -->
    <div id="action_delete" class="bulkAction">
    <p><label><input type="checkbox" name="confirm_deletion" value="1"> {'Are you sure?'|@translate}</label></p>
    </div>

    <!-- associate -->
    <div id="action_associate" class="bulkAction">
          <select style="width:400px" name="associate" size="1">
            {html_options options=$associate_options }
         </select>
<br>{'... or '|@translate}</span><a href="#" class="addAlbumOpen" title="{'create a new album'|@translate}">{'create a new album'|@translate}</a>
    </div>

    <!-- move -->
    <div id="action_move" class="bulkAction">
          <select style="width:400px" name="move" size="1">
            {html_options options=$move_options }
         </select>
<br>{'... or '|@translate}</span><a href="#" class="addAlbumOpen" title="{'create a new album'|@translate}">{'create a new album'|@translate}</a>
    </div>


    <!-- dissociate -->
    <div id="action_dissociate" class="bulkAction">
          <select style="width:400px" name="dissociate" size="1">
            {if !empty($dissociate_options)}{html_options options=$dissociate_options }{/if}
          </select>
    </div>


    <!-- add_tags -->
    <div id="action_add_tags" class="bulkAction">
<select id="tags" name="add_tags">
</select>
    </div>

    <!-- del_tags -->
    <div id="action_del_tags" class="bulkAction">
{if !empty($DEL_TAG_SELECTION)}{$DEL_TAG_SELECTION}{/if}
    </div>

    <!-- author -->
    <div id="action_author" class="bulkAction">
    <label><input type="checkbox" name="remove_author"> {'remove author'|@translate}</label><br>
    {assign var='authorDefaultValue' value='Type here the author name'|@translate}
<input type="text" class="large" name="author" value="{$authorDefaultValue}" onfocus="this.value=(this.value=='{$authorDefaultValue}') ? '' : this.value;" onblur="this.value=(this.value=='') ? '{$authorDefaultValue}' : this.value;">
    </div>    

    <!-- title -->
    <div id="action_title" class="bulkAction">
    <label><input type="checkbox" name="remove_title"> {'remove title'|@translate}</label><br>
    {assign var='titleDefaultValue' value='Type here the title'|@translate}
<input type="text" class="large" name="title" value="{$titleDefaultValue}" onfocus="this.value=(this.value=='{$titleDefaultValue}') ? '' : this.value;" onblur="this.value=(this.value=='') ? '{$titleDefaultValue}' : this.value;">
    </div>

    <!-- date_creation -->
    <div id="action_date_creation" class="bulkAction">
      <label><input type="checkbox" name="remove_date_creation"> {'remove creation date'|@translate}</label><br>
      <div id="set_date_creation">
          <select id="date_creation_day" name="date_creation_day">
             <option value="0">--</option>
            {section name=day start=1 loop=32}
              <option value="{$smarty.section.day.index}" {if $smarty.section.day.index==$DATE_CREATION_DAY}selected="selected"{/if}>{$smarty.section.day.index}</option>
            {/section}
          </select>
          <select id="date_creation_month" name="date_creation_month">
            {html_options options=$month_list selected=$DATE_CREATION_MONTH}
          </select>
          <input id="date_creation_year"
                 name="date_creation_year"
                 type="text"
                 size="4"
                 maxlength="4"
                 value="{$DATE_CREATION_YEAR}">
          <input id="date_creation_linked_date" name="date_creation_linked_date" type="hidden" size="10" disabled="disabled">
      </div>
    </div>

    <!-- level -->
    <div id="action_level" class="bulkAction">
        <select name="level" size="1">
          {html_options options=$level_options selected=$level_options_selected}
        </select>
    </div>

    <!-- metadata -->
    <div id="action_metadata" class="bulkAction">
    </div>

		<!-- generate derivatives -->
		<div id="action_generate_derivatives" class="bulkAction">
			<a href="javascript:selectGenerateDerivAll()">{'All'|@translate}</a>,
			<a href="javascript:selectGenerateDerivNone()">{'None'|@translate}</a>
			<br>
			{foreach from=$generate_derivatives_types key=type item=disp}
				<label><input type="checkbox" name="generate_derivatives_type[]" value="{$type}"> {$disp}</label>
			{/foreach}
			{footer_script}
			function selectGenerateDerivAll() {ldelim}
				$("#action_generate_derivatives input[type=checkbox]").attr("checked", true);
			}
			function selectGenerateDerivNone() {ldelim}
				$("#action_generate_derivatives input[type=checkbox]").attr("checked", false);
			}
			{/footer_script}
		</div>

		<!-- delete derivatives -->
		<div id="action_delete_derivatives" class="bulkAction">
			<a href="javascript:selectDelDerivAll()">{'All'|@translate}</a>,
			<a href="javascript:selectDelDerivNone()">{'None'|@translate}</a>
			<br>
			{foreach from=$del_derivatives_types key=type item=disp}
				<label><input type="checkbox" name="del_derivatives_type[]" value="{$type}"> {$disp}</label>
			{/foreach}
			{footer_script}
			function selectDelDerivAll() {ldelim}
				$("#action_delete_derivatives input[type=checkbox]").attr("checked", true);
			}
			function selectDelDerivNone() {ldelim}
				$("#action_delete_derivatives input[type=checkbox]").attr("checked", false);
			}
			{/footer_script}
		</div>
		
    <!-- progress bar -->
    <div id="regenerationMsg" class="bulkAction" style="display:none">
      <p id="regenerationText" style="margin-bottom:10px;">{'Generate multiple size images'|@translate}</p>
      <span class="progressBar" id="progressBar"></span>
      <input type="hidden" name="regenerateSuccess" value="0">
      <input type="hidden" name="regenerateError" value="0">
    </div>

    <!-- plugins -->
{if !empty($element_set_global_plugins_actions)}
  {foreach from=$element_set_global_plugins_actions item=action}
    <div id="action_{$action.ID}" class="bulkAction">
    {if !empty($action.CONTENT)}{$action.CONTENT}{/if}
    </div>
  {/foreach}
{/if}

    <p id="applyActionBlock" style="display:none" class="actionButtons">
      <input id="applyAction" class="submit" type="submit" value="{'Apply action'|@translate}" name="submit"> <span id="applyOnDetails"></span></p>

    </div> <!-- #permitAction -->
  </fieldset>

  </form>

</div> <!-- #batchManagerGlobal -->
