{known_script id="jquery.tipTip" src=$ROOT_URL|@cat:"themes/default/js/plugins/jquery.tipTip.minified.js" }

<div id="content" class="content">
{$HELP_CONTENT}
</div> <!-- content -->

<ul class="categoryActions">
  <li>
    <a href="#" onclick="window.close();" title="{'Close this window'|@translate}">
      <img src="{$ROOT_URL}{$themeconf.admin_icon_dir}/exit.png" class="button" alt="exit">
    </a>
  </li>
</ul>

