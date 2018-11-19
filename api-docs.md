FORMAT: 1A  
HOST: https://dev.plenar.io/api/v2

# Plenario API, Version 2

Welcome! Plenario is a centralized hub for open data sets from around the world,
ready to search and download. The Plenario API can be used to perform
geospatial and temporal queries. If you’d rather access Plenario’s data through
a visual interface, check out the [Data Explorer](https://dev.plenar.io/explore).

## System Schema

Plenario deals in _data sets_. A data set is more or less exactly what you think
it is: a coherent document of data points for specific topic. Data sets listed with
Plenario must contain a timestamp and a location.

Internally, our schema is

1. `User`s are registered users that _own_ data sets
1. `DataSet`s that contain metadata for a public document: the _source_ data set
1. `Field`s that describe the columns/fields/attributes of the source data set
1. `VirtualDate`s and `VirtualPoint`s that act as bindings for one or more regular
   fields to create a single timestamp or point.

### User

| Attribute | Type    | Default | Required? | Description                         |
| --------- | ------- | ------- | --------- | ----------------------------------- |
| id        | integer |         | Yes       | The primary key                     |
| username  | text    |         | Yes       | The user's name (real or otherwise) |
| bio       | text    | nil     | No        | Biographical information            |
| is_admin? | boolean | false   | Yes       | Is the user a system administrator? |  

### DataSet

| Attribute         | Type      | Default | Required?   | Description                                                               |
| ----------------- | --------- | ------- | ----------- | ------------------------------------------------------------------------- |
| id                | integer   |         | Yes         | The primary key                                                           |
| user_id           | integer   |         | Yes         | Foreign key to `User`                                                     |
| src_type          | text      |         | Yes         | The type of the source document                                           |
| soc_domain        | text      | nil     | Conditional | The domain name for the source                                            |
| soc_4x4           | text      | nil     | Conditional | The 4x4 (id) for the source                                               |
| src_url           | text      | nil     | Conditional | The full path to a web resource                                           |
| description       | text      | nil     | No          | A long form description of the data set                                   |
| attribution       | text      | nil     | No          | Attribution of data set's creator/owner                                   |
| refresh_starts_on | timestamp | nil     | No          | The date the system begins importing the data                             |
| refresh_ends_on   | timestamp | nil     | Conditional | The last date the system imports the data                                 |
| refresh_interval  | text      | nil     | Conditional | A time interval value for scheduling successive imports                   |
| refresh_rate      | integer   | nil     | Conditional | The number of intervals between scheduled imports                         |
| first_import      | timestamp | nil     | No          | The timestamp of the very first import into the system                    |
| latest_import     | timestamp | nil     | No          | The timestamp of the latest import into the system                        |
| next_import       | timestamp | nil     | No          | The timestamp of the next import into the system                          |
| bbox              | geometry  | nil     | No          | The bounding box of the geometries present in the data (calculated)       |
| hull              | geometry  | nil     | No          | The convex hull of the geometries present in the data (calculated)        |
| time_range        | tsrange   | nil     | No          | The lower and upper bounds of timestamps present in the data (calculated) |
| num_records       | integer   | nil     | No          | The number of records in the data (calculated)                            |

#### Conditional Requirements: Source Information

The `src_url` and combination of `soc_domain` and `soc_4x4` are mutually exclusive.
If a data set is sourced directly from Socrata then users can provide the domain and
ID of the resource and we can directly import the data. If the data set is sourced
from a publicly available document then users provide the URL.

#### Conditional Requirements: Refresh Information

The `refresh_ends_on` attribute can only be set if the `refresh_starts_on` value is
given and the end timestamp must be later that the start.

The `refresh_interval` and `refresh_rate` attributes set the schedule for how often
the data set is refreshed from its source. These are only set if the starting timestamp
is set.

### Field

| Attribute   | Type    | Default | Required?   | Description                           |
| ----------- | ------- | ------- | ----------- | ------------------------------------- |
| id          | integer |         | Yes         | The primary key                       |
| data_set_id | integer |         | Yes         | Foreign key to `DataSet`              |
| name        | text    |         | Yes         | The original name of the column       |
| col_name    | text    |         | Yes         | The normalized name of the column     |
| type        | text    |         | Yes         | The database type of the column       |
| description | text    | nil     | No          | A long form description of the column |

### VirtualPoint

| Attribute     | Type    | Default | Required?   | Description                                 |
| ------------- | ------- | ------- | ----------- | ------------------------------------------- |
| id            | integer |         | Yes         | The primary key                             |
| data_set_id   | integer |         | Yes         | Foreign key to `DataSet`                    |
| col_name      | text    |         | Yes         | The normalized, computed name of the column |
| loc_field_id  | integer | nil     | Conditional | Foreign key to `Field`                      |
| lon_field_id  | integer | nil     | Conditional | Foreign key to `Field`                      |
| lat_field_id  | integer | nil     | Conditional | Foreign key to `Field`                      |

#### Conditional Requirements: Field References

Virtual points are made from either a single text field that contains a lat/lon pair or
from two fields that contain lat and lon values. The attributes of the virtual point that
reference these fields are mutually exclusive.

### VirtualDate

| Attribute     | Type    | Default | Required?   | Description                                 |
| ------------- | ------- | ------- | ----------- | ------------------------------------------- |
| id            | integer |         | Yes         | The primary key                             |
| data_set_id   | integer |         | Yes         | Foreign key to `DataSet`                    |
| col_name      | text    |         | Yes         | The normalized, computed name of the column |
| yr_field_id   | integer |         | Yes         | Foreign key to `Field`                      |
| mo_field_id   | integer | nil     | No          | Foreign key to `Field`                      |
| day_field_id  | integer | nil     | No          | Foreign key to `Field`                      |
| hr_field_id   | integer | nil     | No          | Foreign key to `Field`                      |
| min_field_id  | integer | nil     | No          | Foreign key to `Field`                      |
| sec_field_id  | integer | nil     | No          | Foreign key to `Field`                      |

## List Endpoint [/data-sets{?page,size,order,with_user,with_fields,with_virtual_dates,with_virtual_points,bbox,time_range}]

The list endpoint allows you to view metadata for all data sets and filter using
geometries and time ranges.

### Get All Data Sets [GET]

+ Parameters

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200",
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200",
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ]
    }
  }
}

### Paginate [GET]

+ Parameters
  + page (number, optional)
      Sets the page number for long lists of records
      + Default: 1
  + size (number, optional)
      Sets the number of records for a page of records.
      Minimum value is 1 and maximum in 2,000.
      + Default: 200

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200",
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200",
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ]
    }
  }
}

### Order [GET]

+ Parameters
  + order (string, optional)
      Sets the direction and field for ordering records.
      Format must follow `dir:field`.
      + Default: "asc:name"

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200",
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200",
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ]
    }
  }
}

### Include Related Objects [GET]

+ Parameters
  + with_user (boolean, optional)
      Should the response embed the related user?
      + Default: true
  + with_fields (boolean, optional)
      Should the response embed the related fields?
      + Default: true
  + with_virtual_dates (boolean, optional)
      Should the response embed the related virtual dates?
      + Default: true
  + with_virtual_points (boolean, optional)
      Should the response embed the related virtual points?
      + Default: true

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "fields": [
        {
          "col_name": "creation_date",
          "description": null,
          "name": "creation_date",
          "type": "timestamp"
        },
        {
          "col_name": "status",
          "description": null,
          "name": "status",
          "type": "text"
        },
        {
          "col_name": "completion_date",
          "description": null,
          "name": "completion_date",
          "type": "timestamp"
        },
        {
          "col_name": "service_request_number",
          "description": null,
          "name": "service_request_number",
          "type": "text"
        },
        {
          "col_name": "type_of_service_request",
          "description": null,
          "name": "type_of_service_request",
          "type": "text"
        },
        {
          "col_name": "location_of_trees",
          "description": null,
          "name": "location_of_trees",
          "type": "text"
        },
        {
          "col_name": "street_address",
          "description": null,
          "name": "street_address",
          "type": "text"
        },
        {
          "col_name": "zip_code",
          "description": null,
          "name": "zip_code",
          "type": "integer"
        },
        {
          "col_name": "x_coordinate",
          "description": null,
          "name": "x_coordinate",
          "type": "integer"
        },
        {
          "col_name": "y_coordinate",
          "description": null,
          "name": "y_coordinate",
          "type": "integer"
        },
        {
          "col_name": "ward",
          "description": null,
          "name": "ward",
          "type": "integer"
        },
        {
          "col_name": "police_district",
          "description": null,
          "name": "police_district",
          "type": "integer"
        },
        {
          "col_name": "community_area",
          "description": null,
          "name": "community_area",
          "type": "integer"
        },
        {
          "col_name": "latitude",
          "description": null,
          "name": "latitude",
          "type": "integer"
        },
        {
          "col_name": "longitude",
          "description": null,
          "name": "longitude",
          "type": "integer"
        },
        {
          "col_name": "location",
          "description": null,
          "name": "location",
          "type": "geometry"
        },
        {
          "col_name": "location_city",
          "description": null,
          "name": "location_city",
          "type": "text"
        },
        {
          "col_name": "location_address",
          "description": null,
          "name": "location_address",
          "type": "text"
        },
        {
          "col_name": "location_zip",
          "description": null,
          "name": "location_zip",
          "type": "text"
        },
        {
          "col_name": "location_state",
          "description": null,
          "name": "location_state",
          "type": "text"
        },
        {
          "col_name": ":id",
          "description": "The internal Socrata record ID",
          "name": ":id",
          "type": "text"
        },
        {
          "col_name": ":created_at",
          "description": "The timestamp of when the record was first created",
          "name": ":created_at",
          "type": "timestamp"
        },
        {
          "col_name": ":updated_at",
          "description": "The timestamp of when the record was last updated",
          "name": ":updated_at",
          "type": "timestamp"
        }
      ],
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user": {
        "bio": null, 
        "username": "Plenario Admin"
      }
      "user_id": 1,
      "virtual_dates": [],
      "virtual_points": []
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200&with_fields=true&with_user=true&with_virtual_dates=true&with_virtual_points=true", 
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200&with_fields=true&with_user=true&with_virtual_dates=true&with_virtual_points=true", 
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ],
      "with_fields": true, 
      "with_user": true, 
      "with_virtual_dates": true, 
      "with_virtual_points": true
    }
  }
}

### Filter by Bounding Box Contains [GET]

+ Parameters
  + bbox (string, optional)
      Filter the records to those whose bbox _contains_
      a given point. The format of the value must be
      `contains:{ geojson }`.
      + Default: "contains:{\"coordinates\": [-87.8, 42.0], \"crs\": {\"properties\": {\"name\": \"EPSG:4326\"}, \"type\": \"name\"}, \"type\": \"Point\"}"

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?bbox=contains%3A%7B%22coordinates%22%3A+%5B-87.8%2C+42.0%5D%2C+%22crs%22%3A+%7B%22properties%22%3A+%7B%22name%22%3A+%22EPSG%3A4326%22%7D%2C+%22type%22%3A+%22name%22%7D%2C+%22type%22%3A+%22Point%22%7D&order=asc%3Aname&page=1&size=200", 
      "next": "http://localhost:4000/api/v2/data-sets?bbox=contains%3A%7B%22coordinates%22%3A+%5B-87.8%2C+42.0%5D%2C+%22crs%22%3A+%7B%22properties%22%3A+%7B%22name%22%3A+%22EPSG%3A4326%22%7D%2C+%22type%22%3A+%22name%22%7D%2C+%22type%22%3A+%22Point%22%7D&order=asc%3Aname&page=2&size=200", 
      "previous": null
    },
    "query": {
      "bbox_contains": {
        "coordinates": [
          -87.8,
          42.0
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Point"
      },
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ]
    }
  }
}

### Filter by Bounding Box Intersects [GET]

+ Parameters
  + bbox (string, optional)
      Filter the records to those whose bbox _intersects_
      a given geometry. The format of the value must be
      `intersects:{ geojson }`.
      + Default: "intersects:{\"coordinates\": [[[-88.0, 41.0], [-88.0, 43.0], [-85.0, 43.0], [-85.0, 41.0], [-88.0, 41.0]]], \"crs\": {\"properties\": {\"name\": \"EPSG:4326\"}, \"type\": \"name\"}, \"type\": \"Polygon\"}"

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?bbox=intersects%3A%7B%22coordinates%22%3A+%5B%5B%5B-88.0%2C+41.0%5D%2C+%5B-88.0%2C+43.0%5D%2C+%5B-85.0%2C+43.0%5D%2C+%5B-85.0%2C+41.0%5D%2C+%5B-88.0%2C+41.0%5D%5D%5D%2C+%22crs%22%3A+%7B%22properties%22%3A+%7B%22name%22%3A+%22EPSG%3A4326%22%7D%2C+%22type%22%3A+%22name%22%7D%2C+%22type%22%3A+%22Polygon%22%7D&order=asc%3Aname&page=1&size=200", 
      "next": "http://localhost:4000/api/v2/data-sets?bbox=intersects%3A%7B%22coordinates%22%3A+%5B%5B%5B-88.0%2C+41.0%5D%2C+%5B-88.0%2C+43.0%5D%2C+%5B-85.0%2C+43.0%5D%2C+%5B-85.0%2C+41.0%5D%2C+%5B-88.0%2C+41.0%5D%5D%5D%2C+%22crs%22%3A+%7B%22properties%22%3A+%7B%22name%22%3A+%22EPSG%3A4326%22%7D%2C+%22type%22%3A+%22name%22%7D%2C+%22type%22%3A+%22Polygon%22%7D&order=asc%3Aname&page=2&size=200", 
      "previous": null
    },
    "query": {
      "bbox_intersects": {
        "coordinates": [
          [
            [
              -88.0,
              41.0
            ],
            [
              -88.0,
              43.0
            ],
            [
              -85.0,
              43.0
            ],
            [
              -85.0,
              41.0
            ],
            [
              -88.0,
              41.0
            ]
          ]
        ],
        "crs": {
          "properties": {
            "name": "EPSG:4326"
          },
          "type": "name"
        },
        "type": "Polygon"
      },
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ]
    }
  }
}

### Filter by Time Range Contains [GET]

+ Parameters
  + time_range (string, optional)
      Filter the records to those whose time range _contains_
      a given timestamp. The format of the value must
      be `contains:YYYY-mm-ddTHH:MM:SS`.
      + Default: "contains:2018-04-21T15:00:00"

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200&time_range=contains%3A2018-04-21T15%3A00%3A00",
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200&time_range=contains%3A2018-04-21T15%3A00%3A00",
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ],
      "time_range_contains": "2018-04-21T15:00:00"
    }
  }
}

### Filter by Time Range Intersects [GET]

+ Parameters
  + time_range (string, optional)
      Filter the records to those whose time range _intersects_
      a given time range. The format of the value must
      be `intersects:{ time range }`.
      + Default: "intersects:{\"lower\": \"2015-01-01T00:00:00\", \"lower_inclusive\": true, \"upper\": \"2018-01-01T00:00:00\", \"upper_inclusive\": false}"

+ Response 200 (application/json)

{
  "data": [
    {
      "attribution": null,
      "description": null,
      "first_import": "2018-11-15T15:50:00",
      "hull": {
        "geometry": {
          "coordinates": [[
            [-87.613420549815, 41.644600606134],
            [-87.617220726706, 41.645321466737],
            [-87.711006689015, 41.680447122059],
            [-87.800795506966, 41.77455485671],
            [-87.885900661547, 41.997549734494],
            [-87.82067462443,  42.018654921014],
            [-87.674159786454, 42.022534596869],
            [-87.665831486161, 42.022670357197],
            [-87.663624754563, 42.018243899328],
            [-87.605102123245, 41.893276726607],
            [-87.541877754079, 41.744762033174],
            [-87.538955938706, 41.737601255071],
            [-87.524532544316, 41.701829634069],
            [-87.524544944022, 41.700606358679],
            [-87.524646500057, 41.693464784392],
            [-87.53502778049,  41.649287913511],
            [-87.54265242328,  41.645937642876],
            [-87.613420549815, 41.644600606134]
          ]],
          "crs": {
            "properties": { "name": "EPSG:4326" },
            "type": "name"
          },
          "type": "Polygon"
        },
        "type": "Feature"
      },
      "id": 1,
      "latest_import": "2018-11-15T15:52:00",
      "name": "Chicago 311 Tree Trims",
      "next_import": null,
      "num_records": 361694,
      "refresh_ends_on": null,
      "refresh_interval": null,
      "refresh_rate": null,
      "refresh_starts_on": null,
      "slug": "chicago-311-tree-trims",
      "source_url": "https://data.cityofchicago.org/resources/yvxb-fxjz.csv",
      "state": "ready",
      "time_range": {
        "lower": "1971-01-13T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-11-15T09:15:10",
        "upper_inclusive": true
      },
      "user_id": 1
    }
  ],
  "meta": {
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=1&size=200&time_range=intersects%3A%7B%22lower%22%3A+%222015-01-01T00%3A00%3A00%22%2C+%22lower_inclusive%22%3A+true%2C+%22upper%22%3A+%222018-01-01T00%3A00%3A00%22%2C+%22upper_inclusive%22%3A+false%7D",
      "next": "http://localhost:4000/api/v2/data-sets?order=asc%3Aname&page=2&size=200&time_range=intersects%3A%7B%22lower%22%3A+%222015-01-01T00%3A00%3A00%22%2C+%22lower_inclusive%22%3A+true%2C+%22upper%22%3A+%222018-01-01T00%3A00%3A00%22%2C+%22upper_inclusive%22%3A+false%7D",
      "previous": null
    },
    "query": {
      "order": [
        "asc",
        "name"
      ],
      "paginate": [
        1,
        200
      ],
      "time_range_intersects": {
        "lower": "2015-01-01T00:00:00",
        "lower_inclusive": true,
        "upper": "2018-01-01T00:00:00",
        "upper_inclusive": false
      }
    }
  }
}
