# This module contains a set of basic types used in Neutron's Python Interface.
# In all cases, the use of this module is optional. 
# On input, the client can supply a class of his own provided it 
# satisfies the contract - e.g. any class with public x and y attributes
# can be used instead of a Point2. 
# On output, the client can request that JSON is returned, rather than a class.

from math import sqrt
class Point2(object):
    """2D Point class - must have public x and y attributes """
 
    def __init__(self, x=0, y=0):
        self.x = x
        self.y = y
 
    def dist(self, p):
        """return the Euclidian distance between self and p"""
        dx = self.x - p.x
        dy = self.y - p.y
        return sqrt(dx*dx + dy*dy)
 
    def reset(self):
        self.x = 0
        self.y = 0

    def __add__(self, p):
        """return a new point found by adding self and p. This method is
        called by e.g. p+q for points p and q"""
        return Point2(self.x+p.x, self.y+p.y)
 
    def __repr__(self):
        """return a string representation of this point. This method is
        called by the repr() function, and
        also the str() function. It should produce a string that, when
        evaluated, returns a point with the 
        same data."""
        return 'Point2(%f,%f)' % (self.x, self.y)

class Point3(object):
    """3D Point class - must have public x, y, z attributes """
 
    def __init__(self, x=0, y=0, z=0):
        self.x = x
        self.y = y
        self.z = z
 
    def dist(self, p):
        """return the Euclidian distance between self and p"""
        dx = self.x - p.x
        dy = self.y - p.y
        dz = self.z - p.z
        return sqrt(dx*dx + dy*dy + dz*dz)
 
    def reset(self):
        self.x = 0
        self.y = 0
        self.z = 0

    def __add__(self, p):
        """return a new point found by adding self and p. This method is
        called by e.g. p+q for points p and q"""
        return Point3(self.x+p.x, self.y+p.y, self.z+p.z)
 
    def __repr__(self):
        """return a string representation of this point. This method is
        called by the repr() function, and
        also the str() function. It should produce a string that, when
        evaluated, returns a point with the 
        same data."""
        return 'Point3(%f,%f,%f)' % (self.x, self.y, self.z)

class EntityRef(object):
    """An entity ref uses a segment and an entity id and/or a root name """
 
    def __init__(self, segid, entityid=-1, rootid=''):
        self.segId = segid
        self.entityId = entityid
        self.rootId = rootid
 
    def reset(self):
        self.segId = 0
        self.entityId = -1
        self.rootId = ''

    def __repr__(self):
        """return a string representation of this point. This method is
        called by the repr() function, and
        also the str() function. It should produce a string that, when
        evaluated, returns an object with the 
        same data."""
        return 'EntityRef(%d,%d,%s)' % (self.segId, self.entityId, self.rootId)