/* 
Covid 19 Data Exploration
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- 1. First take a look at how many rows we have in each table

SELECT COUNT(*)
FROM covidproject.deaths;

SELECT COUNT(*)
FROM covidproject.vaccinations;


-- 2. Get a feel for the data by looking at all the data

SELECT *
FROM covidproject.deaths;

SELECT *
FROM covidproject.vaccinations;


-- 3. Select the data that we are going to be using, and order by location and date (i.e. 1,2)

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covidproject.deaths
WHERE continent is not NULL
ORDER BY 1,2;


-- 4. Look at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covidproject.deaths
WHERE continent is not NULL
ORDER BY 1,2;


-- 5. Take a look at the Total Cases vs Total Deaths for the United States, ordered by Date descending
-- Shows the likelihood of dying if you contract covid in the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covidproject.deaths
WHERE location LIKE '%States%'
  AND continent is not NULL
ORDER BY 2 DESC;


-- 6. Now do the same as above for Canada
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covidproject.deaths
WHERE location = 'Canada'
  AND continent is not NULL
ORDER BY 2 DESC;


-- 7. Look at Total Cases vs Population in the United States, ordered by date descending
-- Shows the percentage of the population that got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulation
FROM covidproject.deaths
WHERE location LIKE '%States%'
  AND continent is not NULL
ORDER BY 2 DESC;


-- 8. Now do the same as above for Canada, ordered by date descending
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulation
FROM covidproject.deaths
WHERE location = 'Canada'
  AND continent is not NULL
ORDER BY 2 DESC;


-- 9. Let's combine the results so that we can see the Total Cases vs Population for both Canada and the United States on the same dates

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulation
FROM covidproject.deaths
WHERE location = 'Canada' OR
 location LIKE '%States%'
 AND continent is not NULL
ORDER BY 2 DESC;


-- 10. Look at countries with highest infection rate compared to population for each country, ordered by descending PercentPopulationInfected

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM covidproject.deaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- 11. Show countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covidproject.deaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- 12. Show the continents with the highest death count per population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM covidproject.deaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- 13. Global numbers, and doing a caset on new_deaths to make it an integer so that we can do the sum

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM covidproject.deaths
WHERE continent is not NULL
GROUP BY date
ORDER by 1,2;


-- 14. Now let's remove the date so we can see the totals

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM covidproject.deaths
WHERE continent is not NULL
ORDER by 1,2;


-- 15. Now let's join the deaths and vaccinations tables, and create aliases for each table to make it easier to query

SELECT *
FROM covidproject.deaths AS dea
JOIN covidproject.vaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date;


-- 16. Look at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covidproject.deaths AS dea
JOIN covidproject.vaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3;


-- 17. Now we want to see the rolling number of people vaccinated per country over each day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
FROM covidproject.deaths AS dea
JOIN covidproject.vaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3;


-- 18. Use CTE to perform Calculation on Partition By in previous query

WITH PopvsVac
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidproject.deaths AS dea
JOIN covidproject.vaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- 19. Let's try using a Temp Table this time to perform Calculation on Partition By in previous query

CREATE TABLE covidproject.VacRate
(
continent string,
location string,
date datetime,
population int64,
new_vaccinations int64,
RollingPeopleVaccinated int64
);

INSERT INTO covidproject.VacRate
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidproject.deaths AS dea
JOIN covidproject.vaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not NULL
;
Select *, (RollingPeopleVaccinated/Population)*100 as vac_rate
From covidproject.VacRate;
