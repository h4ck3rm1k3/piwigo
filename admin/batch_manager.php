<?php
// +-----------------------------------------------------------------------+
// | Piwigo - a PHP based photo gallery                                    |
// +-----------------------------------------------------------------------+
// | Copyright(C) 2008-2012 Piwigo Team                  http://piwigo.org |
// | Copyright(C) 2003-2008 PhpWebGallery Team    http://phpwebgallery.net |
// | Copyright(C) 2002-2003 Pierrick LE GALL   http://le-gall.net/pierrick |
// +-----------------------------------------------------------------------+
// | This program is free software; you can redistribute it and/or modify  |
// | it under the terms of the GNU General Public License as published by  |
// | the Free Software Foundation                                          |
// |                                                                       |
// | This program is distributed in the hope that it will be useful, but   |
// | WITHOUT ANY WARRANTY; without even the implied warranty of            |
// | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU      |
// | General Public License for more details.                              |
// |                                                                       |
// | You should have received a copy of the GNU General Public License     |
// | along with this program; if not, write to the Free Software           |
// | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, |
// | USA.                                                                  |
// +-----------------------------------------------------------------------+

/**
 * Management of elements set. Elements can belong to a category or to the
 * user caddie.
 *
 */

if (!defined('PHPWG_ROOT_PATH'))
{
  die('Hacking attempt!');
}

include_once(PHPWG_ROOT_PATH.'admin/include/functions.php');
include_once(PHPWG_ROOT_PATH.'admin/include/tabsheet.class.php');

// +-----------------------------------------------------------------------+
// | Check Access and exit when user status is not ok                      |
// +-----------------------------------------------------------------------+

check_status(ACCESS_ADMINISTRATOR);

check_input_parameter('selection', $_POST, true, PATTERN_ID);

// +-----------------------------------------------------------------------+
// |                      initialize current set                           |
// +-----------------------------------------------------------------------+

if (isset($_POST['submitFilter']))
{
  // echo '<pre>'; print_r($_POST); echo '</pre>';
  unset($_REQUEST['start']); // new photo set must reset the page
  $_SESSION['bulk_manager_filter'] = array();

  if (isset($_POST['filter_prefilter_use']))
  {
    $_SESSION['bulk_manager_filter']['prefilter'] = $_POST['filter_prefilter'];
  }

  if (isset($_POST['filter_category_use']))
  {
    $_SESSION['bulk_manager_filter']['category'] = $_POST['filter_category'];

    if (isset($_POST['filter_category_recursive']))
    {
      $_SESSION['bulk_manager_filter']['category_recursive'] = true;
    }
  }

  if (isset($_POST['filter_tags_use']))
  {
    $_SESSION['bulk_manager_filter']['tags'] = get_tag_ids($_POST['filter_tags'], false);

    if (isset($_POST['tag_mode']) and in_array($_POST['tag_mode'], array('AND', 'OR')))
    {
      $_SESSION['bulk_manager_filter']['tag_mode'] = $_POST['tag_mode'];
    }
  }

  if (isset($_POST['filter_level_use']))
  {
    if (in_array($_POST['filter_level'], $conf['available_permission_levels']))
    {
      $_SESSION['bulk_manager_filter']['level'] = $_POST['filter_level'];
      
      if (isset($_POST['filter_level_include_lower']))
      {
        $_SESSION['bulk_manager_filter']['level_include_lower'] = true;
      }
    }
  }
  
  if (isset($_POST['filter_dimension_use']))
  {
    if ( $_POST['filter_dimension'] != 'format' and !preg_match('#^[0-9]+$#', $_POST['filter_dimension_'. $_POST['filter_dimension'] ]) )
    {
      array_push($page['errors'], l10n('Invalid dimension'));
    }
    else
    {
      $_SESSION['bulk_manager_filter']['dimension'] = $_POST['filter_dimension'];
      $_SESSION['bulk_manager_filter']['dimension_'. $_POST['filter_dimension'] ] = $_POST['filter_dimension_'. $_POST['filter_dimension'] ];
    }
  }
}

if (isset($_GET['cat']))
{
  if ('caddie' == $_GET['cat'])
  {
    $_SESSION['bulk_manager_filter'] = array(
      'prefilter' => 'caddie'
      );
  }

  if ('recent' == $_GET['cat'])
  {
    $_SESSION['bulk_manager_filter'] = array(
      'prefilter' => 'last import'
      );
  }

  if (is_numeric($_GET['cat']))
  {
    $_SESSION['bulk_manager_filter'] = array(
      'category' => $_GET['cat']
      );
  }
  
  if (substr_compare($_GET['cat'],'tag-',0,4)==0)
  {
    $_SESSION['bulk_manager_filter']=array();
    $_SESSION['bulk_manager_filter']['tags'] = array(intval(substr($_GET['cat'],4)));
    $_SESSION['bulk_manager_filter']['tag_mode'] = 'AND';
  }
}

if (!isset($_SESSION['bulk_manager_filter']))
{
  $_SESSION['bulk_manager_filter'] = array(
    'prefilter' => 'caddie'
    );
}

// echo '<pre>'; print_r($_SESSION['bulk_manager_filter']); echo '</pre>';

// depending on the current filter (in session), we find the appropriate
// photos
$filter_sets = array();
if (isset($_SESSION['bulk_manager_filter']['prefilter']))
{
  if ('caddie' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    $query = '
SELECT element_id
  FROM '.CADDIE_TABLE.'
  WHERE user_id = '.$user['id'].'
;';
    array_push(
      $filter_sets,
      array_from_query($query, 'element_id')
      );
  }

  if ('last import'== $_SESSION['bulk_manager_filter']['prefilter'])
  {
    $query = '
SELECT MAX(date_available) AS date
  FROM '.IMAGES_TABLE.'
;';
    $row = pwg_db_fetch_assoc(pwg_query($query));
    if (!empty($row['date']))
    {
      $query = '
SELECT id
  FROM '.IMAGES_TABLE.'
  WHERE date_available BETWEEN '.pwg_db_get_recent_period_expression(1, $row['date']).' AND \''.$row['date'].'\'
;';
      array_push(
        $filter_sets,
        array_from_query($query, 'id')
        );
    }
  }

  if ('with no virtual album' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    // we are searching elements not linked to any virtual category
    $query = '
 SELECT id
   FROM '.IMAGES_TABLE.'
 ;';
    $all_elements = array_from_query($query, 'id');

    $query = '
 SELECT id
   FROM '.CATEGORIES_TABLE.'
   WHERE dir IS NULL
 ;';
    $virtual_categories = array_from_query($query, 'id');
    if (!empty($virtual_categories))
    {
      $query = '
 SELECT DISTINCT(image_id)
   FROM '.IMAGE_CATEGORY_TABLE.'
   WHERE category_id IN ('.implode(',', $virtual_categories).')
 ;';
      $linked_to_virtual = array_from_query($query, 'image_id');
    }

    array_push(
      $filter_sets,
      array_diff($all_elements, $linked_to_virtual)
      );
  }

  if ('with no album' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    $query = '
SELECT
    id
  FROM '.IMAGES_TABLE.'
    LEFT JOIN '.IMAGE_CATEGORY_TABLE.' ON id = image_id
  WHERE category_id is null
;';
    array_push(
      $filter_sets,
      array_from_query($query, 'id')
      );
  }

  if ('with no tag' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    $query = '
SELECT
    id
  FROM '.IMAGES_TABLE.'
    LEFT JOIN '.IMAGE_TAG_TABLE.' ON id = image_id
  WHERE tag_id is null
;';
    array_push(
      $filter_sets,
      array_from_query($query, 'id')
      );
  }


  if ('duplicates' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    // we could use the group_concat MySQL function to retrieve the list of
    // image_ids but it would not be compatible with PostgreSQL, so let's
    // perform 2 queries instead. We hope there are not too many duplicates.

    $query = '
SELECT file
  FROM '.IMAGES_TABLE.'
  GROUP BY file
  HAVING COUNT(*) > 1
;';
    $duplicate_files = array_from_query($query, 'file');

    $query = '
SELECT id
  FROM '.IMAGES_TABLE.'
  WHERE file IN (\''.implode("','", $duplicate_files).'\')
;';

    array_push(
      $filter_sets,
      array_from_query($query, 'id')
      );
  }

  if ('all photos' == $_SESSION['bulk_manager_filter']['prefilter'])
  {
    $query = '
SELECT id
  FROM '.IMAGES_TABLE.'
  '.$conf['order_by'];

    $filter_sets[] = array_from_query($query, 'id');
  }

  $filter_sets = trigger_event('perform_batch_manager_prefilters', $filter_sets, $_SESSION['bulk_manager_filter']['prefilter']);
}

if (isset($_SESSION['bulk_manager_filter']['category']))
{
  $categories = array();

  if (isset($_SESSION['bulk_manager_filter']['category_recursive']))
  {
    $categories = get_subcat_ids(array($_SESSION['bulk_manager_filter']['category']));
  }
  else
  {
    $categories = array($_SESSION['bulk_manager_filter']['category']);
  }

  $query = '
 SELECT DISTINCT(image_id)
   FROM '.IMAGE_CATEGORY_TABLE.'
   WHERE category_id IN ('.implode(',', $categories).')
 ;';
  array_push(
    $filter_sets,
    array_from_query($query, 'image_id')
    );
}

if (isset($_SESSION['bulk_manager_filter']['level']))
{
  $operator = '=';
  if (isset($_SESSION['bulk_manager_filter']['level_include_lower']))
  {
    $operator = '<=';
  }
  
  $query = '
SELECT id
  FROM '.IMAGES_TABLE.'
  WHERE level '.$operator.' '.$_SESSION['bulk_manager_filter']['level'].'
  '.$conf['order_by'];

  $filter_sets[] = array_from_query($query, 'id');
}

if (!empty($_SESSION['bulk_manager_filter']['tags']))
{
  array_push(
    $filter_sets,
    get_image_ids_for_tags(
      $_SESSION['bulk_manager_filter']['tags'],
      $_SESSION['bulk_manager_filter']['tag_mode'],
      null,
      null,
      false // we don't apply permissions in administration screens
      )
    );
}

if (isset($_SESSION['bulk_manager_filter']['dimension']))
{
  switch ($_SESSION['bulk_manager_filter']['dimension'])
  {
    case 'min_width':
      $where_clause = 'width >= '.$_SESSION['bulk_manager_filter']['dimension_min_width']; break;
    case 'max_width':
      $where_clause = 'width <= '.$_SESSION['bulk_manager_filter']['dimension_max_width']; break;
    case 'min_height':
      $where_clause = 'height >= '.$_SESSION['bulk_manager_filter']['dimension_min_height']; break;
    case 'max_height':
      $where_clause = 'height <= '.$_SESSION['bulk_manager_filter']['dimension_max_height']; break;
    case 'format':
    {
      switch ($_SESSION['bulk_manager_filter']['dimension_format'])
      {
        case 'portrait':
          $where_clause = 'width/height < 0.95'; break;
        case 'square':
          $where_clause = 'width/height >= 0.95 AND width/height <= 1.05'; break;
        case 'landscape':
          $where_clause = 'width/height > 1.05 AND width/height < 2.5'; break;
        case 'panorama':
          $where_clause = 'width/height >= 2.5'; break;
      }
      break;
    }
  }
  
  $query = '
SELECT id
  FROM '.IMAGES_TABLE.'
  WHERE '.$where_clause.'
  '.$conf['order_by'];

  $filter_sets[] = array_from_query($query, 'id');
}

$current_set = array_shift($filter_sets);
foreach ($filter_sets as $set)
{
  $current_set = array_intersect($current_set, $set);
}
$page['cat_elements_id'] = $current_set;

// +-----------------------------------------------------------------------+
// |                       first element to display                        |
// +-----------------------------------------------------------------------+

// $page['start'] contains the number of the first element in its
// category. For exampe, $page['start'] = 12 means we must show elements #12
// and $page['nb_images'] next elements

if (!isset($_REQUEST['start'])
    or !is_numeric($_REQUEST['start'])
    or $_REQUEST['start'] < 0
    or (isset($_REQUEST['display']) and 'all' == $_REQUEST['display']))
{
  $page['start'] = 0;
}
else
{
  $page['start'] = $_REQUEST['start'];
}

// +-----------------------------------------------------------------------+
// |                                 Tabs                                  |
// +-----------------------------------------------------------------------+
$manager_link = get_root_url().'admin.php?page=batch_manager&amp;mode=';

if (isset($_GET['mode']))
{
  $page['tab'] = $_GET['mode'];
}
else
{
  $page['tab'] = 'global';
}

$tabsheet = new tabsheet();
$tabsheet->set_id('batch_manager');
$tabsheet->select($page['tab']);
$tabsheet->assign();

// +-----------------------------------------------------------------------+
// |                              tags                                     |
// +-----------------------------------------------------------------------+

$query = '
SELECT id, name
  FROM '.TAGS_TABLE.'
;';
$template->assign('tags', get_taglist($query, false));

// +-----------------------------------------------------------------------+
// |                         open specific mode                            |
// +-----------------------------------------------------------------------+

include(PHPWG_ROOT_PATH.'admin/batch_manager_'.$page['tab'].'.php');
?>