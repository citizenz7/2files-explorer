<?php
	$rootdir = "./home";
	$imagedir = "./images";
	$_self = $_SERVER['PHP_SELF'];

	if (!is_dir($rootdir))
	{
		echo "Unable to get access to $rootdir, contact your web administrator.";
		die();
	}

if(isset($_GET['path'])){
	$currentdir = $_GET['path'];
}

	// on tronque le debut si c'est un /
	if (substr($currentdir,0,1) == "/")
	{
		$currentdir = substr($currentdir,1,strlen($currentdir) - 1);
	}

	// si la fin de $currentdir = .. alors on retourne a la racine de ce dossier
	if (substr($currentdir, strlen($currentdir) - 2, 2) == "..")
	{
		// strip last /..
		$currentdir = substr($currentdir, 0, strlen($currentdir) - 3);

		// strip last /dirname
		$currentdir = substr($currentdir, 0, strrpos($currentdir,"/"));
	}

	// si la fin de $currentdir = /. alors on retourne a la racine de ce dossier
	if (substr($currentdir, strlen($currentdir) - 2, 2) == "/.")
	{
		$currentdir = substr($currentdir, 0,strlen($currentdir) - 2);
	}

	// evite tout probleme de securite MAISempeche les nom de rep avec .. dedans
	$currentdir = str_replace("..", "", $currentdir);

	// on traite les actions spéciales
	if(isset($_GET['action'])){
		$action = $_GET['action'];

	switch($action)
	{
		case "mkdir":
			if (isset($_GET['arg']))
			{
				// evite tout probleme de securite MAIS empeche les nom de rep avec .. dedans
				$mkdir = str_replace("..", "", $_GET['arg']);
				// umask 0 = read, write and execute
				umask (0);
				mkdir($rootdir . "/" . $currentdir . "/" . $mkdir);
			}
			else
			{
				$affiche_creer_formulaire = true;

			}
			break;

		case "rm";
			if (isset($_GET['confirmation']))
			{
				// evite tout probleme de securite MAIS empeche les nom de rep avec .. dedans
				$rm = str_replace("..", "", $_GET['path']);

				if (isset($_GET['file']))
				{
					$rm = $rm . "/" . str_replace("..","", $_GET['file']) ;
				}
				system("rm -r '". $rootdir . "/" . $rm . "'") ;
			}
			else
			{
				if(!isset($_GET['infirmation']))
					$affiche_supprimer_formulaire=true;

			}
			// si l'on ne supprimait pas un fichier (donc un rep, on doit retourner a la racine quelque soit la reponse
			if ((isset($_GET['confirmation']) || isset($_GET['infirmation']) ) && ! isset($_GET['file']))
				// strip last /dirname pour retourner au parent du rep en cours
				$currentdir = substr($currentdir, 0, strrpos($currentdir,"/"));
			break;

		case "deconnection":

			break;

		case "upload":
			if (!isset($_FILES['uploadFile']))
			$affiche_upload_formulaire = true;
			break;

	}

}

	// l'upload se fait en post (l'action)
	if (isset($_POST['action']) && $_POST['action'] == "upload")
	{
		if (isset($_FILES['uploadFile']))
		{
			$file_name = $_FILES['uploadFile']['name'];

			// strip file_name of slashes
			$file_name = stripslashes($file_name);
			if ($_POST['date'])
			{
				$file_name = date("d-m-Y-H\hi - ") . $file_name;
			}

			$uploaddir = $rootdir . "/" .  str_replace("..","",urldecode($_POST['path']));

			$file_name = $uploaddir . "/" . str_replace("'","",$file_name);
			$copy = copy($_FILES['uploadFile']['tmp_name'],$file_name);
			// check if successfully copied
			if( ! $copy)
			{
			 	echo basename($file_name) . " | <b>Impossible d'uploader</b>!<br>";
			}
		}
	}
?>

<html>
<head>
<title>Explorateur de fichier - /<?php echo $currentdir; ?></title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css">
</head>
<body>

<div class="container-fluid">
<h2>Explorateur - /<?php echo $currentdir; ?></h2>

<table class="table table-striped">
    <tr>
        <td colspan="2">

        <!-- Toolbar -->
            <table class="table">
                <tr>
                    <td>
			<a href="<?php echo $_self . "?path="; ?>"><i class="fas fa-home"></i> Racine</a> |
			<a href="<?php echo $_self . "?action=mkdir&path=" . urlencode($currentdir); ?>"><i class="fas fa-folder-plus"></i> Creer Repertoire</a> |
			<a href="<?php echo $_self . "?action=upload&path=" . urlencode($currentdir); ?>"><i class="fas fa-upload"></i> Uploader</a>
	           </td>
		   <!--<td align=right>Deconnecter</td>-->
	        </tr>
	    </table>
<?php

if (isset($affiche_creer_formulaire))
{
	// affichage du formulaire pour creer un repertoire
	?>
	<hr>
	<form method="GET">
		<input type="hidden" name="path" value="<?php echo $currentdir ?>">
		<input type="hidden" name="action" value="mkdir">
		Nom du repertoire : <input type="text" name="arg" value="">
		<input type="submit" value="Creer">
	</form>
	<?php
}

if (isset($affiche_supprimer_formulaire))
{
	// affichage du formulaire pour supprimer un repertoire
	?>
	<hr>
	<form method="get">
		<input type="hidden" name="path" value="<?php echo $currentdir ?>">
		<?php
		if ( isset($_GET['file']) )
			echo "<input type=\"hidden\" name=\"file\" value=\"" . $_GET['file'] . "\">";
		?>
		<input type="hidden" name="action" value="rm">
		Supprimer <?php echo $currentdir . "/"; if (isset($_GET['file'])) echo $_GET['file']; ?> ?
		<input type="submit" name="confirmation" value="Oui">
		<input type="submit" name="infirmation" value="Non">
	</form>
	<?php
}

if (isset($affiche_upload_formulaire))
{
	?>
	<hr>
	<form enctype="multipart/form-data" method="post">
		Fichier : <input name="uploadFile" type="file" id="uploadFile">
		<input type="hidden" name="action" value="upload">
		<input type="hidden" name="path" value="<?php echo urlencode($currentdir);?>">
		<input type="submit" name="submit" value="Uploader">
		&nbsp;&nbsp;<input type="checkbox" name="date" CHECKED/>Dater le fichier
	</form>
	<?php
}

?>

</td></tr>
<tr>
<td valign="top" width="20%">
	<!-- Colonne pour les repertoires -->

	<table class="table">
	<tr>
	    <td colspan="3">
		<table class="table">
		    <tr>
		        <td width="100%"><b>Repertoires</b></td>
		    </tr>
		</table>
	    </td>
	</tr>
	<?php
		$directory = opendir( $rootdir . "/" . $currentdir );
		while($dir = readdir($directory))
		{
			if (is_dir( $rootdir . "/" . $currentdir . "/" . $dir) && $dir != "." )
			{
				// on affiche pas le ..  quand on est a la racine
				if($currentdir == "" && $dir != ".." || $currentdir != "")
				{
					echo "<tr><td width=30 height=30>";
					echo "<img width=30 height=28 src=\"" . $imagedir . "/dir.png\">";
					echo "</td><td width=80%>";
					echo "<a href=\"" . $_self . "?path=" . urlencode($currentdir) . "/" . urlencode($dir) . "\">" . $dir . "</a>";
					echo "</td><td align=right>&nbsp;";
					if ( $dir != ".." )
						echo "<a href=\"" . $_self . "?action=rm&path=" . urlencode($currentdir) . "/" . urlencode($dir) . "\"><i class=\"fas fa-trash\"></i></a>";
					echo "</td></tr>\n";
				}
			}
		}
		closedir($directory);
	?>
	</table>
</td>
<td valign="top" width="80%">
	<!-- Colonne pour les fichiers -->

	<table class="table">
	    <tr>
		<td colspan="3">
		    <table class="table">
		        <tr>
		            <td width="75%"><b>Noms</b></td>
		            <td width="25%" align="right"><b>Taille</b></td>
		        </tr>
		    </table>
	         </td>
	    </tr>
	<?php

		$directory = opendir( $rootdir . "/" . $currentdir );
		$foundone = false;
		while( $file = readdir($directory) )
		{
			if (is_file($rootdir . "/" . $currentdir . "/" . $file) )
			{
				$foundone = true;
				echo "<tr><td width=\"30\" height=\"35\">";

				// selon l'extension du fichier
				$ext = strtolower(substr($file,strrpos($file,".") + 1,strlen($file) - strrpos($file,".")));
				switch($ext)
				{
					case "gif":
					case "jpg":
					case "png":
						echo "<img width=30 height=28 src=\"".$rootdir."/miniature.php?gd=2&maxw=30&src=" . $rootdir . "/" . urlencode($currentdir) . "/" . urlencode($file) . "\">";
						break;
					default:
						if (is_file($imagedir . "/" . $ext . ".gif" ))
							echo "<img width=30 height=28 src=\"miniature.php?gd=2&maxw=30&src=" . $imagedir . "/" . $ext . ".gif" . "\">";
						else
							echo strtoupper($ext);
						break;
				}
				echo "</td><td>";
				echo "<a href=\"" . $rootdir . "/" . $currentdir . "/" . $file . "\">" . $file . "</a>";
				echo "</td><td align=right width=15%>";
				echo filesize($rootdir . "/" . $currentdir . "/" . $file );
				echo "&nbsp;&nbsp;<a href=\"" . $_self . "?action=rm&path=" . urlencode($currentdir) . "&file=" . urlencode($file) . "\"><i class=\"fas fa-trash\"></i></a>";
				echo "</td></tr>\n";
			}
		}
		closedir($directory);
		if (!$foundone)
		{
			echo "<tr><td colspan=\"3\" align=\"center\"><b>Aucun fichier !</b></td></tr>";
		}
	?>

	</table>

</td>
</tr>
</table>

</div> <!-- //container-fluid -->

</body>
</html>
