'use strict';
const fetch = require('node-fetch');
const Sequelize = require('sequelize');
const { queue } = require('async');

const API_KEY = process.env.API_KEY;
const DB_URL = process.env.DB_URL || 'postgres://localhost:5432/fasta';
const PG_WORKER = 15;

if (typeof API_KEY === 'undefined' || API_KEY === '') {
  console.error("API_KEY environment variable missing");
  process.exit(1);
} 

const fetchAsync = async (url, options) => {
  const response = await fetch(url, options);
  return await response.json();
}

const sequelize = new Sequelize(DB_URL, {
  pool: { max: PG_WORKER }
});

sequelize.authenticate().catch((e) => {
  console.error(`Cannot authenticate at database: ${e}`);
  process.exit(1);
});

/*
  {
    equipmentnumber: 10095171,
    type: 'ESCALATOR',
    description: 'zu Gleis 2/3',
    geocoordX: 7.58874,
    geocoordY: 50.35085,
    state: 'ACTIVE',
    stateExplanation: 'available',
    stationnumber: 3299
  }
*/

const Facility = sequelize.define('facility', {
  equipmentnumber: {
    type: Sequelize.INTEGER,
    primaryKey: true
  },
  type: {
    type: Sequelize.STRING
  },
  description: {
    type: Sequelize.STRING
  },
  location: {
    type: Sequelize.GEOMETRY('POINT', 4326)
  },
  stationnumber: {
    type: Sequelize.INTEGER
  }
}, {
  timestamps: true
});

const FacilityStatus = sequelize.define('facility_status', {
  equipmentnumber: {
    type: Sequelize.INTEGER
  },
  state: {
    type: Sequelize.STRING
  },
  stateExplanation: {
    type: Sequelize.STRING
  }
}, {
  timestamps: true
});


(async () => {
  await Facility.sync();
  await FacilityStatus.sync();

  let url = 'https://api.deutschebahn.com/fasta/v2/facilities';
  let data = await fetchAsync(url, {headers: {"Accept": "application/json", "Authorization": `Bearer ${API_KEY}`}});
  console.log(`Got ${data.length} items.`);

  let stati = [];
  let facilities = [];

  data.forEach(async (f) => {
    let point = {
      type: 'Point',
      coordinates: [f.geocoordX, f.geocoordY],
      crs: { type: 'name', properties: { name: 'EPSG:4326'} }
    };
    let facility = {
      equipmentnumber: f.equipmentnumber,
      type: f.type,
      description: f.description,
      location: point,
      stationnumber: f.stationnumber
    };
    facilities.push(facility);

    let status = {
      equipmentnumber: f.equipmentnumber,
      state: f.state,
      stateExplanation: f.stateExplanation
    };
    stati.push(status);
  });

  let upsertFacilities = new Promise(async (resolve, reject) => {
    const asyncQueue = queue(async (facility) => (
      Facility.upsert(facility)
    ), PG_WORKER - 2);

    asyncQueue.drain = () => {
      console.log(`upserted ${facilities.length} facilities`);
      resolve();
    };

    asyncQueue.error = (err) => {
      reject(err);
    };

    asyncQueue.push(facilities);
  });
  await upsertFacilities;

  try {
    await FacilityStatus.bulkCreate(stati);
  } catch (e) {
    console.error(e);
  }
  console.log(`inserted ${stati.length} stati`);
  return;
})().then(() => {
  sequelize.close();
  console.log("finished");
  // FIXME: somehow this thing doesn't exit automatically
  process.exit();
});
