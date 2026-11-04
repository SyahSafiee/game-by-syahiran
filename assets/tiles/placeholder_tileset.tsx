<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="placeholder_tileset" tilewidth="16" tileheight="16" tilecount="39" columns="39">
 <image source="placeholder_tileset.png" width="624" height="16"/>
 <tile id="0">
  <!-- grass: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="1">
  <!-- dirt path: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="2">
  <!-- tree: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="3">
  <!-- water: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <!-- Building facades: each building is roof (far row) / wall+window
      (middle rows) / door (row facing the approach corridor). All
      blocking - there's no building interior/warp yet, so the door tile
      is a walkable warp (property `warp`). Each door tile is flanked and
      topped by wall, so it can only be entered from the front. Flat/simple shading pending real pixel art. -->
 <tile id="4">
  <!-- lecture hall / library: roof -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="5">
  <!-- lecture hall / library: wall -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="6">
  <!-- lecture hall / library: window -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="7">
  <!-- lecture hall / library: door -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
   <property name="warp" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="8">
  <!-- hostel: roof -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="9">
  <!-- hostel: wall -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="10">
  <!-- hostel: window -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="11">
  <!-- hostel: door -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
   <property name="warp" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="12">
  <!-- cafeteria / mamak: roof -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="13">
  <!-- cafeteria / mamak: wall -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="14">
  <!-- cafeteria / mamak: window -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="15">
  <!-- cafeteria / mamak: door -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
   <property name="warp" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="16">
  <!-- academic club room: roof -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="17">
  <!-- academic club room: wall -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="18">
  <!-- academic club room: window -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="19">
  <!-- academic club room: door -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
   <property name="warp" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="20">
  <!-- tufted grass: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="21">
  <!-- pink flowers: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="22">
  <!-- yellow flowers: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="23">
  <!-- bush: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="24">
  <!-- bench: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="25">
  <!-- lamp post: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="26">
  <!-- signboard: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="27">
  <!-- cobblestone: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="28">
  <!-- interior floor: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="29">
  <!-- interior wall: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="30">
  <!-- exit mat: walkable, leaves the building -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
   <property name="exit" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="31">
  <!-- bookshelf: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="32">
  <!-- table: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="33">
  <!-- bed: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="34">
  <!-- counter: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="35">
  <!-- plant: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="36">
  <!-- chalkboard: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
 <tile id="37">
  <!-- rug: walkable -->
  <properties>
   <property name="collidable" type="bool" value="false"/>
  </properties>
 </tile>
 <tile id="38">
  <!-- outside the room: blocking -->
  <properties>
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
</tileset>
