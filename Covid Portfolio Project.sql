-- COVID-19 Data Exploration

USE COVID;

--1. Explore CovidDeaths Table (Filtered by Valid Continents)
select * 
from dbo.CovidDeaths
where continent	is not null
order by 3,4;

--2. Explore CovidVaccinations Table

SELECT *
from dbo.CovidVaccinations
order by 3,4;

--3. Select Key Columns for Analysis

select location, continent, date, new_cases,total_cases,  total_deaths, population
from dbo.CovidDeaths
where continent	is not null
order by 1,2;

--4.  Case Fatality Rate Analysis (Nigeria)
-- Likelihood of dying if infected with COVID-19

select location, date, total_cases,  total_deaths, (total_deaths/total_cases)* 100 Death_percentage
from dbo.CovidDeaths
where location like '%nigeria%'
order by 1,2;

--5. Infection Rate vs Population
-- Percentage of population infected over time

select location, date,population, total_cases,  (total_cases/population)*100 InfectionRate
from dbo.CovidDeaths
--where location like '%nigeria%' and
where continent	is not null
order by 1,2;

--6.Countries with Highest Infection Rate

select location,population, MAX(total_cases) HighestInfectionCount, MAx((total_cases/population)*100)
InfectionRate
from dbo.CovidDeaths
where continent	is not null
--where location like '%nigeria%'
group by location, population
order by InfectionRate desc;


--7. Countries with Highest Total Death Count
select location, MAX(cast(total_deaths as int)) TotalDeathCount
from dbo.CovidDeaths
where continent	is not null
group by location, continent
order by TotalDeathCount desc;

--8.Continents with Highest Total Death Count
select continent, MAX(cast(total_deaths as int)) TotalDeathCount
from dbo.CovidDeaths
where continent	is not null
group by continent
order by TotalDeathCount desc;

--9. Global Daily Death Percentage

select Date ,sum(new_cases) TotalCases, SUM(cast(new_deaths as int))TotalDeaths, 
SUM(cast(new_deaths as int))/sum(new_cases) * 100 DeathPercentage
from dbo.CovidDeaths
where continent	is not null
group by Date
order by 1, 2 desc;

--10. Death percentage per continent
select Continent ,sum(new_cases) TotalCases, SUM(cast(new_deaths as int))TotalDeaths, 
SUM(cast(new_deaths as int))/sum(new_cases) * 100 DeathPercentage
from dbo.CovidDeaths
where continent	is not null
group by continent
order by 1, 2 desc;

--11. Total death percentage

select sum(new_cases) TotalCases, SUM(cast(new_deaths as int))TotalDeaths, 
SUM(cast(new_deaths as int))/sum(new_cases) * 100 DeathPercentage
from dbo.CovidDeaths
where continent	is not null;


--12.   Rolling Total of Vaccinations per Location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths dea
join dbo.CovidVaccinations vac
on  dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
and dea.new_vaccinations is not null
order by 2,3;

-- 13. Population vs Vaccination (Using CTE)
-- Calculates Percentage of Population Vaccinated

with PopulationVSVacinnation (Continent, Location, Date,Population,  New_vaccinations, RollingPeopleVaccinated)
as(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths dea
join dbo.CovidVaccinations vac
on  dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--and dea.new_vaccinations is not null
--order by 2,3
)
select *,(RollingPeopleVaccinated/Population) * 100
from PopulationVSVacinnation 
order by 2,3;

--14. Population vs Vaccination (Using Temporary Table)
Drop table if exists #PercentPopluationVaccinated
Create table #PercentPopluationVaccinated
(
Continent nvarchar(255),
loaction nvarchar(255),
Date Datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopluationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths dea
join dbo.CovidVaccinations vac
on  dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--and dea.new_vaccinations is not null
--order by 2,3

select *,(RollingPeopleVaccinated/Population) * 100
from #PercentPopluationVaccinated
where New_vaccinations is not null;

--15. Create View: PercentPopulationVaccinated

Create View PercentPopluationVaccinated as

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths dea
join dbo.CovidVaccinations vac
on  dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--and dea.new_vaccinations is not null
--order by 2,3

--16. Create View: TotalDeathPercentage (Global)

Create view TotalDeathPercentage as

select sum(new_cases) TotalCases, SUM(cast(new_deaths as int))TotalDeaths, 
SUM(cast(new_deaths as int))/sum(new_cases) * 100 DeathPercentage
from dbo.CovidDeaths
where continent	is not null
--order by 1, 2 desc;

-- 17. Top 5 countries by infection rate
SELECT TOP 5 location, 
       MAX(total_cases/population*100) AS MaxInfectionRate
FROM dbo.CovidDeaths
GROUP BY location
ORDER BY MaxInfectionRate DESC;

--18. Top 5 countries by death percentage

SELECT  location, 
       MAX(total_deaths/total_cases*100) AS MaxDeathPercentage 
FROM dbo.CovidDeaths
GROUP BY location
ORDER BY MaxDeathPercentage DESC;

--19.Compare vaccination rates vs infection rates per continent

SELECT dea.continent,
       SUM(cast(vac.new_vaccinations as bigint))/SUM(dea.population)*100 AS VaccinationRate,
       SUM(dea.total_cases)/SUM(dea.population)*100 AS InfectionRate
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
where dea.continent is not null
GROUP BY dea.continent;



























