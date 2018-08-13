FORMAT: 1A  
HOST: https://dev.plenar.io/api/v2

# Plenario API, Version 2

Welcome! Plenario is a centralized hub for open data sets from around the world,
ready to search and download. The Plenario API can be used to perform
geospatial and temporal queries. If you’d rather access Plenario’s data through
a visual interface, check out the [Data Explorer](https://dev.plenar.io/explore).

## What endpoints does the API provide?

There are 3 general endpoints that we will refer to:

- The _list_ endpoint, which is where you can get a listing of all available
  data sets with their metadata (names, source, fields, etc.)
- The _detail_ endpoint, which is where you can page through the records
  of the data sets
- The _aot_ endpoint, which is where you can access information about Array of
  Things networks and page through the observations

## What HTTP specifics are allowed?

### Version

We currently only support HTTP/1.1 .

### Verbs

We support only 3 verbs:

- `GET` to send requests to the endpoints
- `OPTIONS` and `HEAD` are provisionally accepted, but return 204

### Scheme

Everything response is sent over `https`. Requests made to `http` will be
redirected to port 443.

### Request Headers

The following headers have provisional acceptance and support:

- `Accept` declares the format of response data; currently we only
  support responses in `application/json`
- `Accept-Charset` asks for the format of response text; currently we only
  support responses in `UTF-8`
- `Accept-Language` asks for responses to be in a given language; currently
  we only support `en-US`


_Regarding response data format (Accept)_

In the future we may support other response types (such as XML or YAML),
although right now we do not have any specific plans to do so. It will be
driven by demand from our clients.

_Regarding response charsets (Accept-Charset):_

In the future we may support other character encodings other than UTF-8.
For the time being, there doesn't seem to be a compelling argument for anything
else, but that doesn't mean that some day we may need to support UTF-16 for
example.

_Regarding response languages (Accept-Language):_

In the future, we may add translation abilities for some internal aspects of
the system: error messages would be the most likely first candidate. This
will be largely driven through community support.

## Queries

The Plenario API provides several ways to organize and narrow down query
results. Because of the uniform nature of the response data, the following
information can be applied to _all_ of the endpoints exposed by the API.

### Constructing Filters

For any endpoint, you can filter on any property for objects returned under the
`data` key. The way you construct a filter is as follows:
`{property}={operator}:{value}`

- _property_ is the name of the field
- _operator_ is the query operator
- _value_ is the filtering value

**Note:** All parameters are case sensitive.

### Query Operators

| Operator   | PostgreSQL Equivalent           |
| ---------- | ------------------------------- |
| lt         | a < b                           |
| le         | a <= b                          |
| eq         | a = b                           |
| ge         | a >= b                          |
| gt         | a > b                           |
| within     | a <@ b _or_ st_within(a, b)     |
| intersects | a && b _or_ st_intersects(a, b) |

If you need to specify an array of values to filter against, you must format
the property name with square brackets at the end: `?id[]=1&id[]=2`. This will
create a query `id = ANY(1, 2)`.

**Note:** The `within` and `intersects` operators only only work with timestamp
ranges and polygons, and can only be successfully applied to properties whose
value types are applicable. See the _Query Values_ section for more information.

### Query Values

All query values are initially treated as _strings_. When you use a mathematical
operator, PostgreSQL will cast the value.

There are 2 special types of values that the API will attempt to parse: _time
ranges_ and _polygons_.

#### Timestamps

If you are passing a timestamp, it must be formatted as ISO 8601 date time
without timezone information. **All timestamps in Plenario are UTC.**

#### Time Ranges and Polygons

Time ranges and polygons are used with the `within` and `intersects` operators.
When the API picks up either of the operators, it will attempt to parse the
value as a time range first and then a polygon.

While both are passed as encoded JSON, they have different structures and are
safe to be parsed in this order.

##### Timestamp Ranges

Timestamp range values must be URL Encoded JSON. The JSON structure of a time
range is as follows:

```json
{
  "lower": "2018-01-01T00:00:00",
  "upper": "2019-01-01T00:00:00",
  "lower_inclusive": true,
  "upper_inclusive": false,
}
```

You can omit the values for `lower_inclusive` and `upper_inclusive` -- their
values will both be assumed to be `true`.

##### Polygons

Polygon values must be URL Encoded JSON. The JSON structure of a polygon
is as follows:

```json
{
  "type": "Polygon",  // Polygon must be capitalized
  "crs": {
    "type": "name",
    "properties": {
      "name": "EPSG:4326"
    }
  },
  "coordinates": [[
    [2, 2], // [max_x, max_y]
    [2, 1], // [max_x, min_y]
    [1, 1], // [min_x, min_y]
    [1, 2], // [min_x, max_y]
    [2, 2], // [max_x, max_y]
  ]]
}
```

**You must pass the SRID so PostGIS can properly interpolate the value.**

## Responses

There are 3 possible keys at the top level of the response document:

- error
- meta
- data

`error` and `data` are mutually exclusive: if the request errs then
the error message is returned as a string value to the `error` key. If the
request succeeds, the resources are returned as objects within an array under
the `data` key. Successful responses will also include metadata under the
`meta` key.

### Error Response Example

```json
{
  "error": "`page_size` must be a positive integer less than or equal to 5000"
}
```

### Successful Response Example

```json
{
  "meta": {
    "counts": {
      "data_count": 3,
      "total_pages": 1379,
      "total_records": 4137
    },
    "links": {
      "current": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=2&page_size=3",
      "next": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=3&page_size=3",
      "previous": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=1&page_size=3"
    },
    "params": {
      "order_by": {
        "asc": "row_id"
      },
      "page": 2,
      "page_size": 3
    }
  },
  "data": [
    {
      "Beach": "Humboldt",
      "Culture Note": null,
      "Culture Reading Mean": null,
      "Culture Sample 1 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample Interval": null,
      "Culture Test ID": null,
      "DNA Reading Mean": 3241.4,
      "DNA Sample 1 Reading": 3408.0,
      "DNA Sample 2 Reading": 3083.0,
      "DNA Sample Timestamp": "2017-07-22T00:00:00.000000",
      "DNA Test ID": "4359",
      "Latitude": 41.90643,
      "Location": "(41.90643, -87.703717)",
      "Longitude": -87.703717,
      "row_id": 4,
      "vpf_aIFP3fUiEIXRBqKl": {
        "coordinates": [
          -87.703717,
          41.90643
        ],
        "srid": 4326
      }
    }, ...
  ]
}
```

#### The Meta Object

The `meta` object of the response contains metadata about the request and
response.

##### Counts

The `meta.counts` object contains the count of items.

- `meta.counts.data_count` is the number of objects in the `data` array
- `meta.counts.total_pages` is the number of pages to iterate to get every
  record that correlates to the request/query
- `meta.counts.total_records` is the number of records that correlate to the
  request/query

##### Links

The `meta.links` object contains navigation links.

- `meta.links.previous` is the link to the previous page of records
- `meta.links.current` is the link to the current page of records
- `meta.links.next` is the link to the next page of records

##### Params

The `meta.params` object is a reconstruction of the query parameters passed
in the request. It will always have `page`, `page_size` and `order_by` keys,
as the API injects defaults to maintain pagination and ordering.

#### The Data Array

The `data` array of the response contains the records correlated to the
request and query. Even if a request yields no results, this will still be
an array.

## Paging and Ordering Data

As alluded to, the response data has an upper bound of 5,000 records. Most
data sets exceed this value. In order to access all the records of a data
set while enforcing the result cap, we implement paging.

Paging is very simple -- to advance or return to any page, all you need to
do is increment or decrement the page number respectively. We also provide
links to handle paging in the `meta.links` object of the response
so that clients can programmatically page through the data.

Stable paging is contingent upon maintaining consistent order of the data. For
most data set, we inject an internal `row_id` value to the records kept in our
data base. This is a natural count the increments with the rows of the
data we ingest. To put it another way, the order of the source document is
preserved in the database.

### Pagination Query Parameters

- `page` is the page number
- `page_size` is the maximum number of records in the page

Requests without a given `page` number are assumed to be the root of the data
set and default to `page=1`.

Requests without a given `page_size` value default to 200. You can set this
value to any positive integer up to 5,000.

### Ordering Query Parameter

- `order_by` is the order of the records

Ordering is formatted as `order_by={direction}:{field}`. _direction_ can be one
of `asc` or `desc`; _field_ is the field name to order by.

The default value for ordering depends on the endpoint:

- the _list_ endpoint orders by `asc:row_id`
- the _detail_ endpoint orders by `asc:name`
- the _aot_ endpoint orders by `desc:timestamp`

## The List Endpoint [/data-sets{?page,page_size,order_by,time_range,bbox}]

```
/api/v2/data-sets
```

The list endpoint is where you can access metadata about data sets. Metadata
includes names, slugs, sources, refresh cadences, time ranges, bounding
boxes, and other useful information about the data sets.

All fields returned as a data set object in responses are able to be filtered
against. Refer to the filtering, paging and ordering sections above.

### Get All Metadata Entries [GET]

+ Parameters
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "asc:name"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "name"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets?order_by=asc%3Aname&page=1&page_size=200"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": [
    {
      "virtual_points": [
        {
          "name": "vpf_aIFP3fUiEIXRBqKl",
          "lon_field": "Longitude",
          "loc_field": null,
          "lat_field": "Latitude"
        }
      ],
      "virtual_dates": [],
      "user": {
        "name": "Plenario Admin",
        "email": "plenario@uchiago.edu",
        "bio": null
      },
      "time_range": {
        "upper_inclusive": true,
        "upper": "2018-07-25T12:26:00",
        "lower_inclusive": true,
        "lower": "2015-05-26T00:00:00"
      },
      "source_url": "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD",
      "slug": "chicago-beach-lab-dna-tests",
      "refresh_starts_on": null,
      "refresh_rate": "days",
      "refresh_interval": 1,
      "refresh_ends_on": null,
      "next_import": "2018-07-27T15:40:39.789864Z",
      "name": "Chicago Beach Lab - DNA Tests",
      "latest_import": "2018-07-26T15:40:40.971985Z",
      "first_import": "2018-07-26T15:40:39.781226Z",
      "fields": [
        {
          "type": "text",
          "name": "DNA Test ID",
          "description": null
        },
        {
          "type": "timestamp",
          "name": "DNA Sample Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Beach",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 1 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 2 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Test ID",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Note",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample Interval",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Timestamp",
          "description": null
        },
        {
          "type": "float",
          "name": "Latitude",
          "description": null
        },
        {
          "type": "float",
          "name": "Longitude",
          "description": null
        },
        {
          "type": "text",
          "name": "Location",
          "description": null
        }
      ],
      "description": "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
      "bbox": {
        "srid": 4326,
        "coordinates": [
          [
            [
              42.0213,
              -87.703717
            ],
            [
              41.7142,
              -87.703717
            ],
            [
              41.7142,
              -87.5299
            ],
            [
              42.0213,
              -87.5299
            ],
            [
              42.0213,
              -87.703717
            ]
          ]
        ]
      },
      "attribution": "City of Chicago"
    }
  ]
}

### Filter By Time Range [GET]

+ Parameters
  + time_range (object, optional)
      Metadata entries list the time range of the records of the data set. These
      ranges can be filtered by supplying your own `tsrange` and checking for
      an intersection. **Note:** to filter with a time range in the list
      endpoint you must use the `intersects:` operator. **Example:**

      ```
      {
        "lower": "2017-01-01T00:00:00",
        "upper": "2018-01-01T00:00:00",
        "lower_inclusive": true,
        "upper_inclusive": false
      }
      ```

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "time_range": {
        "intersects": {
          "upper_inclusive": false,
          "upper": "2018-01-01T00:00:00",
          "lower_inclusive": true,
          "lower": "2017-01-01T00:00:00"
        }
      },
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "name"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets?order_by=asc%3Aname&page=1&page_size=200&time_range=intersects%3A%7B%22lower%22%3A%222017-01-01T00%3A00%3A00%22%2C%22upper%22%3A%222018-01-01T00%3A00%3A00%22%2C%22lower_inclusive%22%3Atrue%2C%22upper_inclusive%22%3Afalse%7D"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": [
    {
      "virtual_points": [
        {
          "name": "vpf_aIFP3fUiEIXRBqKl",
          "lon_field": "Longitude",
          "loc_field": null,
          "lat_field": "Latitude"
        }
      ],
      "virtual_dates": [],
      "user": {
        "name": "Plenario Admin",
        "email": "plenario@uchiago.edu",
        "bio": null
      },
      "time_range": {
        "upper_inclusive": true,
        "upper": "2018-07-25T12:26:00",
        "lower_inclusive": true,
        "lower": "2015-05-26T00:00:00"
      },
      "source_url": "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD",
      "slug": "chicago-beach-lab-dna-tests",
      "refresh_starts_on": null,
      "refresh_rate": "days",
      "refresh_interval": 1,
      "refresh_ends_on": null,
      "next_import": "2018-07-27T15:40:39.789864Z",
      "name": "Chicago Beach Lab - DNA Tests",
      "latest_import": "2018-07-26T15:40:40.971985Z",
      "first_import": "2018-07-26T15:40:39.781226Z",
      "fields": [
        {
          "type": "text",
          "name": "DNA Test ID",
          "description": null
        },
        {
          "type": "timestamp",
          "name": "DNA Sample Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Beach",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 1 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 2 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Test ID",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Note",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample Interval",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Timestamp",
          "description": null
        },
        {
          "type": "float",
          "name": "Latitude",
          "description": null
        },
        {
          "type": "float",
          "name": "Longitude",
          "description": null
        },
        {
          "type": "text",
          "name": "Location",
          "description": null
        }
      ],
      "description": "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
      "bbox": {
        "srid": 4326,
        "coordinates": [
          [
            [
              42.0213,
              -87.703717
            ],
            [
              41.7142,
              -87.703717
            ],
            [
              41.7142,
              -87.5299
            ],
            [
              42.0213,
              -87.5299
            ],
            [
              42.0213,
              -87.703717
            ]
          ]
        ]
      },
      "attribution": "City of Chicago"
    }
  ]
}

### Filter By Bounding Box [GET]

+ Parameters
  + bbox (object, optional)
      Metadata entries list the bounding box of the records of the data set.
      These bboxes can be filtered by supplying your own `polygon` and checking
      for an intersection. **Note:** to filter with a bbox in the list endpoint
      you must use the `intersects` operator. **Example:**

      ```
      {
        "type": "Polygon",
        "crs": {
          "type": "name",
          "properties": {
            "name": "EPSG:4326"
          }
        },
        "coordinates": [[
          [-88,43],
          [-85,43],
          [-85,40],
          [-88,40],
          [-88,43]
        ]]
      }
      ```

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "bbox": {
        "intersects": {
          "srid": 4326,
          "coordinates": [[
            [-88,43],
            [-85,43],
            [-85,40],
            [-88,40],
            [-88,43]
          ]]
        }
      },
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "name"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets?order_by=asc%3Aname&page=1&page_size=200&time_range=intersects%3A%7B%22lower%22%3A%222017-01-01T00%3A00%3A00%22%2C%22upper%22%3A%222018-01-01T00%3A00%3A00%22%2C%22lower_inclusive%22%3Atrue%2C%22upper_inclusive%22%3Afalse%7D"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": [
    {
      "virtual_points": [
        {
          "name": "vpf_aIFP3fUiEIXRBqKl",
          "lon_field": "Longitude",
          "loc_field": null,
          "lat_field": "Latitude"
        }
      ],
      "virtual_dates": [],
      "user": {
        "name": "Plenario Admin",
        "email": "plenario@uchiago.edu",
        "bio": null
      },
      "time_range": {
        "upper_inclusive": true,
        "upper": "2018-07-25T12:26:00",
        "lower_inclusive": true,
        "lower": "2015-05-26T00:00:00"
      },
      "source_url": "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD",
      "slug": "chicago-beach-lab-dna-tests",
      "refresh_starts_on": null,
      "refresh_rate": "days",
      "refresh_interval": 1,
      "refresh_ends_on": null,
      "next_import": "2018-07-27T15:40:39.789864Z",
      "name": "Chicago Beach Lab - DNA Tests",
      "latest_import": "2018-07-26T15:40:40.971985Z",
      "first_import": "2018-07-26T15:40:39.781226Z",
      "fields": [
        {
          "type": "text",
          "name": "DNA Test ID",
          "description": null
        },
        {
          "type": "timestamp",
          "name": "DNA Sample Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Beach",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 1 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 2 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Test ID",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Note",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample Interval",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Timestamp",
          "description": null
        },
        {
          "type": "float",
          "name": "Latitude",
          "description": null
        },
        {
          "type": "float",
          "name": "Longitude",
          "description": null
        },
        {
          "type": "text",
          "name": "Location",
          "description": null
        }
      ],
      "description": "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
      "bbox": {
        "srid": 4326,
        "coordinates": [
          [
            [
              42.0213,
              -87.703717
            ],
            [
              41.7142,
              -87.703717
            ],
            [
              41.7142,
              -87.5299
            ],
            [
              42.0213,
              -87.5299
            ],
            [
              42.0213,
              -87.703717
            ]
          ]
        ]
      },
      "attribution": "City of Chicago"
    }
  ]
}

## The List @head Directive [/data-sets/@head]

```
/api/v2/data-sets/@head
```

There is a special `@head` endpoint that can be used to get the first
metadata record that satisfies the request/query. This is a convenience
shortcut to inspect the output of the endpoint. It doesn't have much value
beyond that.

All filters and ordering options available to general list endpoint are
applicable here.

### Getting the List Head [GET]

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "name"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets/@head?order_by=asc%3Aname&page=1&page_size=200"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": [
    {
      "virtual_points": [
        {
          "name": "vpf_aIFP3fUiEIXRBqKl",
          "lon_field": "Longitude",
          "loc_field": null,
          "lat_field": "Latitude"
        }
      ],
      "virtual_dates": [],
      "user": {
        "name": "Plenario Admin",
        "email": "plenario@uchiago.edu",
        "bio": null
      },
      "time_range": {
        "upper_inclusive": true,
        "upper": "2018-07-25T12:26:00",
        "lower_inclusive": true,
        "lower": "2015-05-26T00:00:00"
      },
      "source_url": "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD",
      "slug": "chicago-beach-lab-dna-tests",
      "refresh_starts_on": null,
      "refresh_rate": "days",
      "refresh_interval": 1,
      "refresh_ends_on": null,
      "next_import": "2018-07-27T15:40:39.789864Z",
      "name": "Chicago Beach Lab - DNA Tests",
      "latest_import": "2018-07-26T15:40:40.971985Z",
      "first_import": "2018-07-26T15:40:39.781226Z",
      "fields": [
        {
          "type": "text",
          "name": "DNA Test ID",
          "description": null
        },
        {
          "type": "timestamp",
          "name": "DNA Sample Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Beach",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 1 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Sample 2 Reading",
          "description": null
        },
        {
          "type": "float",
          "name": "DNA Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Test ID",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Timestamp",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 1 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Reading",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Reading Mean",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Note",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample Interval",
          "description": null
        },
        {
          "type": "text",
          "name": "Culture Sample 2 Timestamp",
          "description": null
        },
        {
          "type": "float",
          "name": "Latitude",
          "description": null
        },
        {
          "type": "float",
          "name": "Longitude",
          "description": null
        },
        {
          "type": "text",
          "name": "Location",
          "description": null
        }
      ],
      "description": "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
      "bbox": {
        "srid": 4326,
        "coordinates": [
          [
            [
              42.0213,
              -87.703717
            ],
            [
              41.7142,
              -87.703717
            ],
            [
              41.7142,
              -87.5299
            ],
            [
              42.0213,
              -87.5299
            ],
            [
              42.0213,
              -87.703717
            ]
          ]
        ]
      },
      "attribution": "City of Chicago"
    }
  ]
}

## The Detail Endpoint [/data-sets/{slug}{?page,page_size,order_by,vpf_aIFP3fUiEIXRBqKl}]

```
/data-sets/:slug
```

The detail endpoint is where you can access the records of the data sets. Each
data set is unique, and therefor filtering and ordering are unique to each data
set. However, each data set maintains an injected `row_id`. The row identifier
is a natural integer that is applied row by row as the source document of the
data set is ingested to preserve order.

Paging works just as in all other endpoints by specifying `page_size` and
`page`.

It is also important to note that parameters are case sensitive. This can be
a stumbling point when creating queries, as some data sets do not normalize
their field names. Where you would expect a field to be named `event_location`,
it could be named `Event Location` instead. Take care to inspect the fields
of the data set either by the _list_ endpoint or the special _detail describe_
endpoint (information below).

There are two other concepts worth introducing here: virtual date and virtual
point fields. Plenario is indexed by place and time. Most data sets are unable
to serialize their data regarding these values in formats other than plain
text. In order to accommodate these constraints we offer the ability to combine
and parse `timestamp` and `point` values from one or more regular fields.

Virtual dates consist of a minimum year value and default to January first at
midnight of that year. The virtual date fields are prefixed with `vdf_`. As you
inspect the metadata of the data set, you will see a special section that lists
them. They are all interpreted by the database and application as `timestamps`
without timezone. Virtual dates are uncommon, but they do exist.

Virtual points are created by either a latitude/longitude pair of fields or a
single field that lists both values. Virtual point fields are prefixed with
`vpf_`. As you inspect the metadata of the data set, you will see a special
section that lists them. They are interpreted by the database and application
as `geometry(point, 4326)`.

It's also worth noting that virtual points are extremely common. If you are
planning to filter your requests with a bounding box, you should take care in
calling the metadata endpoint for the data set to get the name of the field(s)
you wish to filter on, as filtering requires single field assignment.

### Getting all Records of a Data Set [GET]

+ Parameters
  + slug (string, required)
      The _slug_ is the formatted name of the data set. In our examples, we will
      be querying the _Chicago Beach Lab - DNA Tests_ data set. Its slug is
      `chicago-beach-lab-dna-tests`.
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "asc:name"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "page_size": 2,
      "page": 10,
      "order_by": {
        "asc": "row_id"
      }
    },
    "links": {
      "previous": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=9&page_size=2",
      "next": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=11&page_size=2",
      "current": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=10&page_size=2"
    },
    "counts": {
      "total_records": 4137,
      "total_pages": 2069,
      "data_count": 2
    }
  },
  "data": [
    {
      "vpf_aIFP3fUiEIXRBqKl": {
        "srid": 4326,
        "coordinates": [
          -87.6152,
          41.8935
        ]
      },
      "row_id": 19,
      "Longitude": -87.6152,
      "Location": "(41.8935, -87.6152)",
      "Latitude": 41.8935,
      "DNA Test ID": "3095",
      "DNA Sample Timestamp": "2017-06-21T00:00:00.000000",
      "DNA Sample 2 Reading": 54,
      "DNA Sample 1 Reading": 48,
      "DNA Reading Mean": 50.9,
      "Culture Test ID": null,
      "Culture Sample Interval": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 1 Reading": null,
      "Culture Reading Mean": null,
      "Culture Note": null,
      "Beach": "Ohio Street"
    },
    {
      "vpf_aIFP3fUiEIXRBqKl": {
        "srid": 4326,
        "coordinates": [
          -87.5299,
          41.7142
        ]
      },
      "row_id": 20,
      "Longitude": -87.5299,
      "Location": "(41.7142, -87.5299)",
      "Latitude": 41.7142,
      "DNA Test ID": "2905",
      "DNA Sample Timestamp": "2017-06-14T00:00:00.000000",
      "DNA Sample 2 Reading": 384,
      "DNA Sample 1 Reading": 860,
      "DNA Reading Mean": 574.7,
      "Culture Test ID": null,
      "Culture Sample Interval": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 1 Reading": null,
      "Culture Reading Mean": null,
      "Culture Note": null,
      "Beach": "Calumet"
    }
  ]
}

### Filtering a Virtual Point Field [GET]

As mentioned before, the names of fields for each data set are unique. This is
also true for virtual points. In our example the name of the virtual point
field of the data set is `vpf_aIFP3fUiEIXRBqKl`. In real world uses, this
name will be different (for both this data set and all others).

+ Parameters
  + slug (string, required)
      The _slug_ is the formatted name of the data set. In our examples, we will
      be querying the _Chicago Beach Lab - DNA Tests_ data set. Its slug is
      `chicago-beach-lab-dna-tests`.
  + vpf_aIFP3fUiEIXRBqKl (object, optional)
      Filter the records of the data sets by this field. In this particular
      example, we are filtering a point field using a bounding box -- all
      records returned must exist within that box. **NOTE:** for this query to
      succeed we also must use the `within:` operator. **Example:**

      ```
      {
        "type": "Polygon",
        "crs": {
          "type": "name",
          "properties": {
            "name": "EPSG:4326"
          }
        },
        "coordinates": [[
          [-87.65449, 41.9878],
          [-87.65451, 41.9878],
          [-87.65451, 41.9876],
          [-87.65449, 41.9876],
          [-87.65449, 41.9878]
        ]]
      }
      ```

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "vpf_aIFP3fUiEIXRBqKl": {
        "within": {
          "srid": 4326,
          "coordinates": [
            [
              [
                -87.65449,
                41.9878
              ],
              [
                -87.65451,
                41.9878
              ],
              [
                -87.65451,
                41.9876
              ],
              [
                -87.65449,
                41.9876
              ],
              [
                -87.65449,
                41.9878
              ]
            ]
          ]
        }
      },
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "row_id"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests?order_by=asc%3Arow_id&page=1&page_size=200&vpf_aIFP3fUiEIXRBqKl=within%3A%7B%22type%22%3A%22Polygon%22%2C%22crs%22%3A%7B%22type%22%3A%22name%22%2C%22properties%22%3A%7B%22name%22%3A%22EPSG%3A4326%22%7D%7D%2C%22coordinates%22%3A%5B%5B%5B-87.65449%2C41.9878%5D%2C%5B-87.65451%2C41.9878%5D%2C%5B-87.65451%2C41.9876%5D%2C%5B-87.65449%2C41.9876%5D%2C%5B-87.65449%2C41.9878%5D%5D%5D%7D"
    },
    "counts": {
      "total_records": 162,
      "total_pages": 1,
      "data_count": 162
    }
  },
  "data": [
    {
      "vpf_aIFP3fUiEIXRBqKl": {
        "srid": 4326,
        "coordinates": [
          -87.6545,
          41.9877
        ]
      },
      "row_id": 3,
      "Longitude": -87.6545,
      "Location": "(41.9877, -87.6545)",
      "Latitude": 41.9877,
      "DNA Test ID": "5451",
      "DNA Sample Timestamp": "2017-08-23T00:00:00.000000",
      "DNA Sample 2 Reading": 247,
      "DNA Sample 1 Reading": 87,
      "DNA Reading Mean": 146.6,
      "Culture Test ID": null,
      "Culture Sample Interval": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 1 Reading": null,
      "Culture Reading Mean": null,
      "Culture Note": null,
      "Beach": "Osterman"
    },
    {
      "vpf_aIFP3fUiEIXRBqKl": {
        "srid": 4326,
        "coordinates": [
          -87.6545,
          41.9877
        ]
      },
      "row_id": 23,
      "Longitude": -87.6545,
      "Location": "(41.9877, -87.6545)",
      "Latitude": 41.9877,
      "DNA Test ID": "3641",
      "DNA Sample Timestamp": "2017-07-04T00:00:00.000000",
      "DNA Sample 2 Reading": 385,
      "DNA Sample 1 Reading": 534,
      "DNA Reading Mean": 453.4,
      "Culture Test ID": null,
      "Culture Sample Interval": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 1 Reading": null,
      "Culture Reading Mean": null,
      "Culture Note": null,
      "Beach": "Osterman"
    }, ...
  ]
}

## The Detail @head Directive [/data-sets/{slug}/@head{?page,page_size,order_by,vpf_aIFP3fUiEIXRBqKl}]

```
/data-sets/:slug/@head
```

Just like the list head endpoint, you can get the first record of a detail
endpoint by appending `/@head` to the resource route. This is a convenience
shortcut to inspect the output of the endpoint. It doesn't have much value
beyond that.

All filters and ordering options available to general detail endpoint are
applicable here.

### Getting the Detail Head [GET]

We're going to recycle the query of the last example (filtering with a bounding
box on a virtual point field) and use the `@head` directive to only get the
first record.

+ Parameters
  + slug (string, required)
      The _slug_ is the formatted name of the data set. In our examples, we will
      be querying the _Chicago Beach Lab - DNA Tests_ data set. Its slug is
      `chicago-beach-lab-dna-tests`.

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "vpf_aIFP3fUiEIXRBqKl": {
        "within": {
          "srid": 4326,
          "coordinates": [
            [
              [
                -87.65449,
                41.9878
              ],
              [
                -87.65451,
                41.9878
              ],
              [
                -87.65451,
                41.9876
              ],
              [
                -87.65449,
                41.9876
              ],
              [
                -87.65449,
                41.9878
              ]
            ]
          ]
        }
      },
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "row_id"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests/@head?order_by=asc%3Arow_id&page=1&page_size=200&vpf_aIFP3fUiEIXRBqKl=within%3A%7B%22type%22%3A%22Polygon%22%2C%22crs%22%3A%7B%22type%22%3A%22name%22%2C%22properties%22%3A%7B%22name%22%3A%22EPSG%3A4326%22%7D%7D%2C%22coordinates%22%3A%5B%5B%5B-87.65449%2C41.9878%5D%2C%5B-87.65451%2C41.9878%5D%2C%5B-87.65451%2C41.9876%5D%2C%5B-87.65449%2C41.9876%5D%2C%5B-87.65449%2C41.9878%5D%5D%5D%7D"
    },
    "counts": {
      "total_records": 162,
      "total_pages": 1,
      "data_count": 162
    }
  },
  "data": [
    {
      "vpf_aIFP3fUiEIXRBqKl": {
        "srid": 4326,
        "coordinates": [
          -87.6545,
          41.9877
        ]
      },
      "row_id": 3,
      "Longitude": -87.6545,
      "Location": "(41.9877, -87.6545)",
      "Latitude": 41.9877,
      "DNA Test ID": "5451",
      "DNA Sample Timestamp": "2017-08-23T00:00:00.000000",
      "DNA Sample 2 Reading": 247,
      "DNA Sample 1 Reading": 87,
      "DNA Reading Mean": 146.6,
      "Culture Test ID": null,
      "Culture Sample Interval": null,
      "Culture Sample 2 Timestamp": null,
      "Culture Sample 2 Reading": null,
      "Culture Sample 1 Timestamp": null,
      "Culture Sample 1 Reading": null,
      "Culture Reading Mean": null,
      "Culture Note": null,
      "Beach": "Osterman"
    }
  ]
}

## The Detail @describe Directive [/data-sets/{slug}/@describe]

```
/data-sets/:slug/@describe
```

Just like the general list endpoint, the describe directive of the detail
endpoint will provide you with all the metadata for the data set specified in
the resource path (the slug). All you need to do is append `/@describe` to the
resource.

Filters, paging, and ordering are not applicable as this is a single resource
and are unnecessary.

### Getting the Detail Metadata [GET]

+ Parameters
  + slug (string, required)
      The _slug_ is the formatted name of the data set. In our examples, we will
      be querying the _Chicago Beach Lab - DNA Tests_ data set. Its slug is
      `chicago-beach-lab-dna-tests`.

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "page_size": 200,
      "page": 1,
      "order_by": {
        "asc": "row_id"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/data-sets/chicago-beach-lab-dna-tests/@describe?order_by=asc%3Arow_id&page=1&page_size=200"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": {
    "virtual_points": [
      {
        "name": "vpf_aIFP3fUiEIXRBqKl",
        "lon_field": "Longitude",
        "loc_field": null,
        "lat_field": "Latitude"
      }
    ],
    "virtual_dates": [],
    "user": {
      "name": "Plenario Admin",
      "email": "plenario@uchiago.edu",
      "bio": null
    },
    "time_range": {
      "upper_inclusive": true,
      "upper": "2018-07-25T12:26:00",
      "lower_inclusive": true,
      "lower": "2015-05-26T00:00:00"
    },
    "source_url": "https://data.cityofchicago.org/api/views/hmqm-anjq/rows.csv?accessType=DOWNLOAD",
    "slug": "chicago-beach-lab-dna-tests",
    "refresh_starts_on": null,
    "refresh_rate": "days",
    "refresh_interval": 1,
    "refresh_ends_on": null,
    "next_import": "2018-07-27T15:40:39.789864Z",
    "name": "Chicago Beach Lab - DNA Tests",
    "latest_import": "2018-07-26T15:40:40.971985Z",
    "first_import": "2018-07-26T15:40:39.781226Z",
    "fields": [
      {
        "type": "text",
        "name": "DNA Test ID",
        "description": null
      },
      {
        "type": "timestamp",
        "name": "DNA Sample Timestamp",
        "description": null
      },
      {
        "type": "text",
        "name": "Beach",
        "description": null
      },
      {
        "type": "float",
        "name": "DNA Sample 1 Reading",
        "description": null
      },
      {
        "type": "float",
        "name": "DNA Sample 2 Reading",
        "description": null
      },
      {
        "type": "float",
        "name": "DNA Reading Mean",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Test ID",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Sample 1 Timestamp",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Sample 1 Reading",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Sample 2 Reading",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Reading Mean",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Note",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Sample Interval",
        "description": null
      },
      {
        "type": "text",
        "name": "Culture Sample 2 Timestamp",
        "description": null
      },
      {
        "type": "float",
        "name": "Latitude",
        "description": null
      },
      {
        "type": "float",
        "name": "Longitude",
        "description": null
      },
      {
        "type": "text",
        "name": "Location",
        "description": null
      }
    ],
    "description": "Lorem Ipsum\nDNA Chicago Beaches\nDolor Sit Amet",
    "bbox": {
      "srid": 4326,
      "coordinates": [
        [
          [
            42.0213,
            -87.703717
          ],
          [
            41.7142,
            -87.703717
          ],
          [
            41.7142,
            -87.5299
          ],
          [
            42.0213,
            -87.5299
          ],
          [
            42.0213,
            -87.703717
          ]
        ]
      ]
    },
    "attribution": "City of Chicago"
  }
}

## The Array of Things Endpoint [/aot{?network_name,node_id,timestamp,location,page,page_size,order_by}]

```
/api/v2/aot
```

### About AoT Data

Pleanrio is the official front end to the data released by
[The Array of Things](https://arrayofthings.github.io/) (AoT).

Plenario treats AoT data as a white label data set -- where in traditional data
sets we have very clear segmentation (think _Chicago Beach Lab - DNA Tests_ vs.
_Chicago Beach Lab - Culture Tests_), under the AoT umbrella we combine several
sources of information.

AoT data comes from different _networks_. A network is a deployment of _nodes_.
A node is a physical device made up of several _sensors_. A sensor is a physical
device onboard a node that records observations about the environment.

The AoT team partners with many municipalities, universities and other entities
to deploy nodes, and those nodes are tracked by those groups: hence the concept
of networks.

Nodes have similar configurations of sensors, but to be clear not every node
is guaranteed to have the same; even within a network. This is because AoT is
an ongoing experiment. Some sensors are mature and built into every node; some
sensors are newer and are being actively calibrated; some sensors are
provisionally added to test for usefulness and efficacy.

Under the hood, we treat AoT data very differently than traditional data. AoT
data is broken into three models internally, which is relevant to the design
of the API:

- _AoT Metadata_ contains information about networks
- _AoT Data_ contains the recorded observations of all nodes
- _AoT Observations_ contains a detailed break down of the observations for
  cleaner filtering

### The AoT API Design

The AoT Endpoint (`/api/v2/aot`) acts as a list endpoint with an additional
`/@describe` directive to access metadata -- the describe directive does not
exist in the traditional endpoint, and, unlike the detail endpoint, the
directive applies to all metadata under the AoT umbrella. We also provide a
`/@head` directive like the other endpoints.

It is important to note that in addition to the paging and ordering parameters
in the other endpoints, the AoT endpoint has another parameter necessary to
maintaining stable pagination: the _window_ parameter.

While other, traditional data sets update their data periodically, AoT data is
updated every 5 minutes -- and the amount of new data added is staggering. In
order to maintain stable pagination we have to limit the query results to a
specific maximum timestamp -- the window.

### Getting all AoT Data [GET]

Note that the _window_ parameter is the timestamp the query came in, and
does not change in subsequent paging results.

+ Parameters
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-12T13:14:55",
      "page_size": 2,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      }
    },
    "links": {
      "previous": null,
      "next": "http://localhost:4000/api/v2/aot?order_by=desc%3Atimestamp&page=2&page_size=2&window=2018-08-12T13%3A14%3A55",
      "current": "http://localhost:4000/api/v2/aot?order_by=desc%3Atimestamp&page=1&page_size=2&window=2018-08-12T13%3A14%3A55"
    },
    "counts": {
      "total_records": 35957,
      "total_pages": 17979,
      "data_count": 2
    }
  },
  "data": [
    {
      "timestamp": "2018-07-26T15:00:19.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.65
        },
        "HTU21D": {
          "temperature": 26.53,
          "humidity": 39.06
        },
        "BMP180": {
          "temperature": 33.4,
          "pressure": 1017.57
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    },
    {
      "timestamp": "2018-07-26T15:00:44.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.69
        },
        "HTU21D": {
          "temperature": 26.58,
          "humidity": 39.01
        },
        "BMP180": {
          "temperature": 33.5,
          "pressure": 1017.65
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

### Filter By Network Name [GET]

+ Parameters
  + network_name (string, optional)
      Filters the results to records whose network name matches the parameter.
      Network names are the `slug` values in the network metadata. **Example:**
      `chicago`.
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:17:49",
      "page_size": 1,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      },
      "network_name": {
        "eq": "Chicago"
      }
    },
    "links": {
      "previous": null,
      "next": "http://localhost:4000/api/v2/aot?network_name=Chicago&order_by=desc%3Atimestamp&page=2&page_size=1&window=2018-08-13T15%3A17%3A49",
      "current": "http://localhost:4000/api/v2/aot?network_name=Chicago&order_by=desc%3Atimestamp&page=1&page_size=1&window=2018-08-13T15%3A17%3A49"
    },
    "counts": {
      "total_records": 38522,
      "total_pages": 38522,
      "data_count": 1
    }
  },
  "data": [
    {
      "timestamp": "2018-07-26T15:00:19.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.65
        },
        "HTU21D": {
          "temperature": 26.53,
          "humidity": 39.06
        },
        "BMP180": {
          "temperature": 33.4,
          "pressure": 1017.57
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

### Filter By a Single Node ID [GET]

+ Parameters
  * node_id (string, optional)
      Filters the results to records whose `node_id` matches the parameter.
      **Example:** `080`
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:19:08",
      "page_size": 2,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      },
      "node_id": {
        "eq": "080"
      }
    },
    "links": {
      "previous": null,
      "next": "http://localhost:4000/api/v2/aot?node_id=080&order_by=desc%3Atimestamp&page=2&page_size=2&window=2018-08-13T15%3A19%3A08",
      "current": "http://localhost:4000/api/v2/aot?node_id=080&order_by=desc%3Atimestamp&page=1&page_size=2&window=2018-08-13T15%3A19%3A08"
    },
    "counts": {
      "total_records": 1328,
      "total_pages": 664,
      "data_count": 2
    }
  },
  "data": [
    {
      "timestamp": "2018-07-26T15:00:19.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.65
        },
        "HTU21D": {
          "temperature": 26.53,
          "humidity": 39.06
        },
        "BMP180": {
          "temperature": 33.4,
          "pressure": 1017.57
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    },
    {
      "timestamp": "2018-07-26T15:00:44.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.69
        },
        "HTU21D": {
          "temperature": 26.58,
          "humidity": 39.01
        },
        "BMP180": {
          "temperature": 33.5,
          "pressure": 1017.65
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

### Filter By Several Node IDs [GET]

+ Parameters
  * node_id (string, optional)
      Filters the results to records whose `node_id` matches the parameter. When
      you need to filter by multiple IDs, you must append `[]` to the key.
      **Example:**

      ```
      ?node_id[]=080&node_id[]=081
      ```
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:19:57",
      "page_size": 2,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      },
      "node_id": {
        "in": [
          "080",
          "081"
        ]
      }
    },
    "links": {
      "previous": null,
      "next": "http://localhost:4000/api/v2/aot?node_id[]=080&node_id[]=081&order_by=desc%3Atimestamp&page=2&page_size=2&window=2018-08-13T15%3A19%3A57",
      "current": "http://localhost:4000/api/v2/aot?node_id[]=080&node_id[]=081&order_by=desc%3Atimestamp&page=1&page_size=2&window=2018-08-13T15%3A19%3A57"
    },
    "counts": {
      "total_records": 2546,
      "total_pages": 1273,
      "data_count": 2
    }
  },
  "data": [
    {
      "timestamp": "2018-07-26T15:00:19.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.65
        },
        "HTU21D": {
          "temperature": 26.53,
          "humidity": 39.06
        },
        "BMP180": {
          "temperature": 33.4,
          "pressure": 1017.57
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    },
    {
      "timestamp": "2018-07-26T15:00:44.000000",
      "observations": {
        "TSYS01": {
          "temperature": 27.69
        },
        "HTU21D": {
          "temperature": 26.58,
          "humidity": 39.01
        },
        "BMP180": {
          "temperature": 33.5,
          "pressure": 1017.65
        }
      },
      "node_id": "080",
      "longitude": -87.659672,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.659672,
          41.96904
        ]
      },
      "latitude": 41.96904,
      "human_address": " Broadway Ave & Lawrence Ave Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

### Filter by Timestamp [GET]

+ Parameters
  + timestamp (object, optional)
    AoT observations are timestamped. These records can be filtered by
    supplying a `tsrange` and checking for containment. **Note:** to filter with
    a time range in the AoT endpoint you must use the `within:` operator.
    **Example:**

    ```
    {
      "lower": "2018-08-01T00:00:00",
      "upper": "2018-09-01T00:00:00",
      "lower_inclusive": true,
      "upper_inclusive": false
    }
    ```
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:23:07",
      "timestamp": {
        "within": {
          "upper_inclusive": false,
          "upper": "2018-09-01T00:00:00",
          "lower_inclusive": true,
          "lower": "2018-08-01T00:00:00"
        }
      },
      "page_size": 1,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      }
    },
    "links": {
      "previous": null,
      "next": "http://localhost:4000/api/v2/aot?order_by=desc%3Atimestamp&page=2&page_size=1&timestamp=within%3A%7B%22lower%22%3A%222018-08-01T00%3A00%3A00%22%2C%22upper%22%3A%222018-09-01T00%3A00%3A00%22%2C%22lower_inclusive%22%3Atrue%2C%22upper_inclusive%22%3Afalse%7D&window=2018-08-13T15%3A23%3A07",
      "current": "http://localhost:4000/api/v2/aot?order_by=desc%3Atimestamp&page=1&page_size=1&timestamp=within%3A%7B%22lower%22%3A%222018-08-01T00%3A00%3A00%22%2C%22upper%22%3A%222018-09-01T00%3A00%3A00%22%2C%22lower_inclusive%22%3Atrue%2C%22upper_inclusive%22%3Afalse%7D&window=2018-08-13T15%3A23%3A07"
    },
    "counts": {
      "total_records": 36625,
      "total_pages": 36625,
      "data_count": 1
    }
  },
  "data": [
    {
      "timestamp": "2018-08-01T19:24:53.000000",
      "observations": {
        "TSYS01": {
          "temperature": 31.51
        },
        "BMP180": {
          "temperature": 31.29
        }
      },
      "node_id": "025",
      "longitude": -87.685806,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.685806,
          41.857797
        ]
      },
      "latitude": 41.857797,
      "human_address": " Western Ave & 18th St Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

### Filter By Location [GET]

+ Parameters
  + location (object, optional)
    Filter the records of the AoT observations. **NOTE:** for this query to
    succeed we also must use the `within:` operator. **Example:**

    ```
    {
      "type": "Polygon",
      "crs": {
        "type": "name",
        "properties": {
          "name": "EPSG:4326"
        }
      },
      "coordinates": [[
        [-87.65449, 41.9878],
        [-87.65451, 41.9878],
        [-87.65451, 41.9876],
        [-87.65449, 41.9876],
        [-87.65449, 41.9878]
      ]]
    }
    ```
  + page (number, optional)
      Sets the page number of the records returned.
      + Default: 1
  + page_size (number, optional)
      Sets the maximum number of records in the page.
      + Default: 200
  + order_by (string, optional)
      Orders the records. Format follows `order_by={asc|desc}:{field}`.
      + Default: "desc:timestamp"

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:24:31",
      "page_size": 1,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      },
      "location": {
        "within": {
          "srid": 4326,
          "coordinates": [
            [
              [
                -87.65449,
                41.9878
              ],
              [
                -87.65451,
                41.9878
              ],
              [
                -87.65451,
                41.9876
              ],
              [
                -87.65449,
                41.9876
              ],
              [
                -87.65449,
                41.9878
              ]
            ]
          ]
        }
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/aot?location=within%3A%7B%22type%22%3A%22Polygon%22%2C%22crs%22%3A%7B%22type%22%3A%22name%22%2C%22properties%22%3A%7B%22name%22%3A%22EPSG%3A4326%22%7D%7D%2C%22coordinates%22%3A%5B%5B%5B-87.65449%2C41.9878%5D%2C%5B-87.65451%2C41.9878%5D%2C%5B-87.65451%2C41.9876%5D%2C%5B-87.65449%2C41.9876%5D%2C%5B-87.65449%2C41.9878%5D%5D%5D%7D&order_by=desc%3Atimestamp&page=1&page_size=1&window=2018-08-13T15%3A24%3A31"
    },
    "counts": {
      "total_records": 0,
      "total_pages": 1,
      "data_count": 0
    }
  },
  "data": []
}

## The AoT @head Directive [/aot/@head{?timestamp}]

```
/aot/@head
```

Just like the list head endpoint, you can get the first record of the AoT
endpoint by appending `/@head` to the resource route. This is a convenience
shortcut to inspect the output of the endpoint. It doesn't have much value
beyond that.

All filters and ordering options available to general AoT endpoint are
applicable here.

### Getting the AoT Head [GET]

We're going to recycle the timestamp example and use the `@head` directive to
only get the first record.

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:27:26",
      "timestamp": {
        "within": {
          "upper_inclusive": false,
          "upper": "2018-09-01T00:00:00",
          "lower_inclusive": true,
          "lower": "2018-08-01T00:00:00"
        }
      },
      "page_size": 1,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/aot/@head?order_by=desc%3Atimestamp&page=1&page_size=1&timestamp=within%3A%7B%22lower%22%3A%222018-08-01T00%3A00%3A00%22%2C%22upper%22%3A%222018-09-01T00%3A00%3A00%22%2C%22lower_inclusive%22%3Atrue%2C%22upper_inclusive%22%3Afalse%7D&window=2018-08-13T15%3A27%3A26"
    },
    "counts": {
      "total_records": 37000,
      "total_pages": 37000,
      "data_count": 1
    }
  },
  "data": [
    {
      "timestamp": "2018-08-01T19:24:53.000000",
      "observations": {
        "TSYS01": {
          "temperature": 31.51
        },
        "BMP180": {
          "temperature": 31.29
        }
      },
      "node_id": "025",
      "longitude": -87.685806,
      "location": {
        "srid": 4326,
        "coordinates": [
          -87.685806,
          41.857797
        ]
      },
      "latitude": 41.857797,
      "human_address": " Western Ave & 18th St Chicago IL",
      "aot_meta": {
        "slug": "chicago",
        "network_name": "Chicago"
      }
    }
  ]
}

## The AoT @describe Directive [/aot/@describe]

```
/aot/@describe
```

Just like the general list endpoint, the describe directive of the AoT
endpoint will provide you with all the metadata for the data sets specified in
the request/query. All you need to do is append `/@describe` to the
resource.

All filters and ordering options available to general AoT endpoint are
applicable here.

### Getting the Detail Metadata [GET]

+ Response 200 (application/json)

{
  "meta": {
    "params": {
      "window": "2018-08-13T15:30:37",
      "page_size": 200,
      "page": 1,
      "order_by": {
        "desc": "timestamp"
      }
    },
    "links": {
      "previous": null,
      "next": null,
      "current": "http://localhost:4000/api/v2/aot/@describe?order_by=desc%3Atimestamp&page=1&page_size=200&window=2018-08-13T15%3A30%3A37"
    },
    "counts": {
      "total_records": 1,
      "total_pages": 1,
      "data_count": 1
    }
  },
  "data": [
    {
      "time_range": {
        "upper_inclusive": true,
        "upper": "2018-08-13T15:22:36",
        "lower_inclusive": true,
        "lower": "2018-07-26T15:00:14"
      },
      "source_url": "http://www.mcs.anl.gov/research/projects/waggle/downloads/beehive1/plenario.json",
      "slug": "chicago",
      "network_name": "Chicago",
      "fields": [
        {
          "type": "text",
          "name": "node_id"
        },
        {
          "type": "text",
          "name": "human_address"
        },
        {
          "type": "float",
          "name": "latitude"
        },
        {
          "type": "float",
          "name": "longitude"
        },
        {
          "type": "timestamp",
          "name": "timestamp"
        },
        {
          "type": "object",
          "name": "observations"
        },
        {
          "type": "geometry(point, 4326)",
          "name": "location"
        }
      ],
      "bbox": {
        "srid": 4326,
        "coordinates": [
          [
            [
              41.96904,
              -87.761072
            ],
            [
              41.713867,
              -87.761072
            ],
            [
              41.713867,
              -87.536509
            ],
            [
              41.96904,
              -87.536509
            ],
            [
              41.96904,
              -87.761072
            ]
          ]
        ]
      }
    }
  ]
}
