<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.11.0" name="placeholder_tileset" tilewidth="16" tileheight="16" tilecount="4" columns="4">
 <image source="placeholder_tileset.png" width="64" height="16"/>
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
  <!-- wall / tree: blocking -->
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
</tileset>
