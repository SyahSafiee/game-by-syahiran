<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="placeholder_tileset" tilewidth="16" tileheight="16" tilecount="20" columns="20">
 <image source="placeholder_tileset.png" width="320" height="16"/>
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
      is a visual placeholder for a future enterable entrance, not a real
      one. Flat/simple shading pending real pixel art. -->
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
   <property name="collidable" type="bool" value="true"/>
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
   <property name="collidable" type="bool" value="true"/>
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
   <property name="collidable" type="bool" value="true"/>
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
   <property name="collidable" type="bool" value="true"/>
  </properties>
 </tile>
</tileset>
